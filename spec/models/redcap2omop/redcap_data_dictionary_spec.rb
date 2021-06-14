require 'rails_helper'
require 'support/shared_examples/with_soft_delete'
module Redcap2omop
  RSpec.describe RedcapDataDictionary, type: :model do
    let(:redcap_data_dictionary) { FactoryBot.create(:redcap_data_dictionary) }
    let(:subject)     { redcap_data_dictionary }

    describe 'associations' do
      it { is_expected.to belong_to(:redcap_project) }
      it { is_expected.to have_many(:redcap_events) }
      it { is_expected.to have_many(:redcap_variables) }
    end

    include_examples 'with soft_delete'

    describe 'methods' do
      it 'sets next version for the first record' do
        expect(redcap_data_dictionary.version).to eq 1
      end

      it 'sets next version for the next record' do
        dictionary = FactoryBot.create(:redcap_data_dictionary, redcap_project: redcap_data_dictionary.redcap_project)
        expect(dictionary.version).to eq 2
      end

      it 'does not set version until record is validated' do
        dictionary = Redcap2omop::RedcapDataDictionary.new
        expect(dictionary.version).to eq nil
      end

      it 'does not set assign version if record is not linked to a project' do
        dictionary = Redcap2omop::RedcapDataDictionary.new
        dictionary.valid?
        expect(dictionary.version).to eq 1
      end

      it 'does not set assigns version upon validation if record is linked to a project' do
        dictionary = Redcap2omop::RedcapDataDictionary.new(redcap_project: redcap_data_dictionary.redcap_project)
        dictionary.valid?
        expect(dictionary.version).to eq 2
      end

      it 'does not update version on existing record' do
        version = redcap_data_dictionary.version
        redcap_data_dictionary.touch
        expect(redcap_data_dictionary.version).to eq version
      end

      it 'checks if a Redcap variable does not exist', focus: false do
        expect(redcap_data_dictionary.redcap_variable_exist?('moomin')).to be_falsey
      end

      it 'checks if a Redcap variable does exist', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'moomin')
        expect(redcap_data_dictionary.redcap_variable_exist?('moomin')).to be_truthy
      end

      it 'checks if a Redcap variable does not exist (because it has beend deleted)', focus: false do
        redcap_variable = FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'moomin')
        expect(redcap_data_dictionary.redcap_variable_exist?('moomin')).to be_truthy
        redcap_variable.destroy!
        expect(redcap_data_dictionary.redcap_variable_exist?('moomin')).to be_falsey
      end

      it 'checks if a Redcap variable has not changed its field type', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'moomin', field_type: 'dropdown', text_validation_type: nil)
        expect(redcap_data_dictionary.redcap_variable_field_type_changed?('moomin', 'dropdown', nil)).to be_falsy
      end

      it 'checks if a Redcap variable has changed its field type', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'moomin', field_type: 'slider', text_validation_type: nil)
        expect(redcap_data_dictionary.redcap_variable_field_type_changed?('moomin', 'dropdown', nil)).to be_truthy
      end

      it 'checks if a Redcap variable has changed its field type (even if it does not exist)', focus: false do
        expect(redcap_data_dictionary.redcap_variable_field_type_changed?('moomin', 'dropdown', nil)).to be_nil
      end
    end
  end
end