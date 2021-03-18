require 'rails_helper'
require 'support/helpers/stub_requests'

RSpec.describe Redcap2omop::DataServices::RedcapImport do
  describe 'importing records from redcap' do
    let(:project)   { FactoryBot.create(:redcap_project) }
    let(:service)   { Redcap2omop::DataServices::RedcapImport.new(redcap_project: project) }
    let(:json_body) { File.read('spec/support/data/test_records.json')}

    describe 'when import is successful' do
      before(:each) do
        project.api_token = Faker::Lorem.word
        stub_redcap_api_record_request(body: json_body)
      end

      after(:each) do
        ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS #{project.export_table_name}"
      end

      it 'creates new table for redcap import data if does not exist' do
        sql = "SELECT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='#{project.export_table_name}');"
        result = ActiveRecord::Base.connection.select_all(sql).first
        expect(result['exists']).to eq false
        service.run
        result = ActiveRecord::Base.connection.select_all(sql).first
        expect(result['exists']).to eq true
      end

      it 'loads data into project specific table' do
        result = service.run
        inserted_records = ActiveRecord::Base.connection.select_all("select * from #{project.export_table_name}").to_a
        json_data = JSON.parse(json_body)

        inserted_records.each{|r| r.each{|k,v| r[k] = '' if v.blank? }}

        expect((inserted_records - json_data).length).to eq 0
        expect((json_data - inserted_records).length).to eq 0
      end

      it 'returns success' do
        expect(service.run.success).to eq true
      end
    end

    context 'when import fails' do
      it 'raises error if project API token is blank' do
        project.api_token = nil
        result = service.run
        expect(result.success).to eq false
        expect(result.message).to eq 'project api token is missing'
      end

      it 'raises error if retrieving data fails' do
        project.api_token = Faker::Lorem.word
        stub_redcap_api_record_request(body: '[]')
        error = 'failed to connect'
        allow_any_instance_of(Redcap2omop::Webservices::RedcapApi).to receive(:records).and_return({ error: error })
        result = service.run
        expect(result.success).to eq false
        expect(result.message).to eq 'error retrieving records from REDCap: ' + error
      end
    end
  end
end

