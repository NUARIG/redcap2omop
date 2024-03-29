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

      it 'checks if a Redcap variable does not exist (because it has been deleted)', focus: false do
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

      it 'checks if a Redcap variable has changed its field label', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'moomin', field_label: 'Favorite Moomin?', field_type: 'slider', text_validation_type: nil)
        expect(redcap_data_dictionary.redcap_variable_field_label_changed?('moomin', 'Best Moomin?')).to be_truthy
      end

      it 'checks if a Redcap variable has changed its field label (even if it does not exist)', focus: false do
        expect(redcap_data_dictionary.redcap_variable_field_label_changed?('moomin', 'Best Moomin?')).to be_nil
      end

      it 'checks if a Redcap variable has changed its choices', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        expect(redcap_data_dictionary.redcap_variable_choices_changed?('clock_position_of_wound', "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock")).to be_truthy
      end

      it 'checks if a Redcap variable has changed its choices (even if it does not exist)', focus: false do
        expect(redcap_data_dictionary.redcap_variable_choices_changed?('clock_position_of_wound', "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")).to be_nil
      end

      it 'checks if a Redcap variable choice does not exist', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        expect(redcap_data_dictionary.redcap_variable_choice_exist?('clock_position_of_wound', '7')).to be_falsey
      end

      it 'checks if a Redcap variable does exist', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        expect(redcap_data_dictionary.redcap_variable_choice_exist?('clock_position_of_wound', '1')).to be_truthy
      end

      it 'checks if a Redcap variable choice has changed its description if it does not exist', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        expect(redcap_data_dictionary.redcap_variable_choice_description_changed?('clock_position_of_wound', '7', "9 o'clock")).to be_falsey
      end

      it 'checks if a Redcap variable choice has not changed its description if it does exist', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        expect(redcap_data_dictionary.redcap_variable_choice_description_changed?('clock_position_of_wound', '6', "8 o'clock")).to be_falsey
      end

      it 'checks if a Redcap variable choice has changed its description if it does exist', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        expect(redcap_data_dictionary.redcap_variable_choice_description_changed?('clock_position_of_wound', '6', "8 o'clock moomin")).to be_truthy
      end

      it 'can find a Redcap variable', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        expect(redcap_data_dictionary.find_redcap_variable('clock_position_of_wound')).to be_truthy
      end

      it 'does not find a Redcap variable if it does not eixit', focus: false do
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        expect(redcap_data_dictionary.find_redcap_variable('clock_position_of_wound_moomin')).to be_falsey
      end
    end
  end
end