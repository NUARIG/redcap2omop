require 'rails_helper'
require 'support/helpers/stub_requests'

RSpec.describe Redcap2omop::DictionaryServices::RedcapImport do
  describe 'parsing dictionary from redcap' do
    let(:project)   { FactoryBot.create(:redcap_project) }
    let(:service)   { Redcap2omop::DictionaryServices::RedcapImport.new(redcap_project: project) }
    let(:json_body) { File.read('spec/support/data/test_dictionary.json')}

    describe 'when import is successful' do
      before(:each) do
        project.api_token = Faker::Lorem.word
        stub_redcap_api_metadata_request(body: json_body)
      end

      it 'creates new dictionary' do
        expect{ service.run }.to change{ Redcap2omop::RedcapDataDictionary.count }.by(1)
        expect(Redcap2omop::RedcapDataDictionary.last.redcap_project).to eq project
      end

      it 'creates redcap variables', focus: false do
        expect(Redcap2omop::RedcapVariable.count).to eq 0
        expect{ service.run }.to change{ Redcap2omop::RedcapVariable.count }.by(39)
        Redcap2omop::RedcapVariable.all.each do |redcap_variable|
          expect(redcap_variable.redcap_data_dictionary.redcap_project).to eq project
        end
        variable = Redcap2omop::RedcapVariable.get_by_name('dob')
        expect(variable).not_to be_nil
        expect(variable.form_name).to eq 'demographics'
        expect(variable.field_type).to eq 'text'
        expect(variable.text_validation_type).to eq 'date_ymd'
        expect(variable.field_label).to eq 'Date of Birth'
        expect(variable.choices).to be_blank
        expect(variable.field_annotation).to be_blank

        variable = Redcap2omop::RedcapVariable.get_by_name('last_name')
        expect(variable).not_to be_nil
        expect(variable.form_name).to eq 'demographics'
        expect(variable.field_type).to eq 'text'
        expect(variable.text_validation_type).to be_blank
        expect(variable.field_label).to eq 'Last Name'
        expect(variable.choices).to be_blank
        expect(variable.field_annotation).to be_blank

        variable = Redcap2omop::RedcapVariable.get_by_name('gender')
        expect(variable).not_to be_nil
        expect(variable.form_name).to eq 'demographics'
        expect(variable.field_type).to eq 'radio'
        expect(variable.text_validation_type).to be_blank
        expect(variable.field_label).to eq 'Gender'
        expect(variable.choices).to eq "1, Cis Female | 2, Trans Female | 3, Cis Male | 4, Transe Male | 5, Non-binary"
        expect(variable.field_annotation).to be_blank
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
        stub_redcap_api_metadata_request(body: '[]')
        error = 'failed to connect'
        allow_any_instance_of(Redcap2omop::Webservices::RedcapApi).to receive(:metadata).and_return({ error: error })
        result = service.run
        expect(result.success).to eq false
        expect(result.message).to eq 'error retrieving metadata data from REDCap: ' + error
      end

      it 'does not save new dictionary' do
        expect{ service.run }.not_to change{ Redcap2omop::RedcapDataDictionary.count }
      end

      it 'does not create redcap variables' do
        expect{ service.run }.not_to change{ Redcap2omop::RedcapVariable.count }
      end

      it 'does not save new dictionary' do
        allow_any_instance_of(Redcap2omop::RedcapVariable).to receive(:valid?).and_return(false)
        project.api_token = Faker::Lorem.word
        stub_redcap_api_metadata_request(body: json_body)
        expect(service.run.message).to eq 'Validation failed: '
      end
    end
  end
end
