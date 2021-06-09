require 'rails_helper'
require 'support/shared_examples/with_soft_delete'
module Redcap2omop
  RSpec.describe RedcapProject, type: :model do
    let(:redcap_project) { FactoryBot.create(:redcap_project) }
    let(:subject)        { redcap_project }

    describe 'associations' do
      it { is_expected.to have_many(:redcap_data_dictionaries) }
    end

    describe 'validations' do
      it { is_expected.to validate_uniqueness_of(:export_table_name) }
      it { is_expected.to validate_presence_of(:export_table_name) }
    end

    describe 'methods' do
      it 'returns type concept' do
        expect(redcap_project.type_concept).to eq Redcap2omop::Concept.where(domain_id: 'Type Concept', concept_code: 'OMOP4976882').first
      end

      it 'sets export table name' do
        expect(redcap_project.export_table_name).to eq "redcap_records_tmp_#{redcap_project.id}"
        new_redcap_project = FactoryBot.build(:redcap_project)
        expect(new_redcap_project.export_table_name).to eq "redcap_records_tmp_#{redcap_project.id + 1}"
      end

      it 'returns the current version of the Redcap data dictionary', focus: true do
        expect(redcap_project.redcap_data_dictionaries.size).to eq 0
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create(version: 1)
        redcap_project.reload
        expect(redcap_project.current_redcap_data_dictionary).to eq redcap_data_dictionary
        new_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create(version: 2)
        expect(redcap_project.current_redcap_data_dictionary).to eq new_redcap_data_dictionary
      end
    end

    describe 'scopes' do
      it 'returns csv_importable projects' do
        redcap_project.api_import = false
        redcap_project.save!
        expect(Redcap2omop::RedcapProject.csv_importable).to match_array([redcap_project])

        redcap_project.api_import = true
        redcap_project.save!
        expect(Redcap2omop::RedcapProject.csv_importable).to be_empty
      end

      it 'returns api_importable projects' do
        redcap_project.api_import = false
        redcap_project.save!
        expect(Redcap2omop::RedcapProject.api_importable).to be_empty

        redcap_project.api_import = true
        redcap_project.save!
        expect(Redcap2omop::RedcapProject.api_importable).to match_array([redcap_project])
      end
    end

    include_examples 'with soft_delete'
  end
end
