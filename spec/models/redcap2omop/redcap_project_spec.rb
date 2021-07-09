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

      it 'returns the current version of the Redcap data dictionary', focus: false do
        expect(redcap_project.redcap_data_dictionaries.size).to eq 0
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        redcap_project.reload
        expect(redcap_project.current_redcap_data_dictionary).to eq redcap_data_dictionary
        new_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        expect(redcap_project.current_redcap_data_dictionary).to eq new_redcap_data_dictionary
      end

      it 'returns the pior version of the Redcap data dictionary', focus: false do
        expect(redcap_project.redcap_data_dictionaries.size).to eq 0
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create(version: 1)
        redcap_project.reload
        expect(redcap_project.current_redcap_data_dictionary).to eq redcap_data_dictionary
        new_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create(version: 2)
        expect(redcap_project.prior_redcap_data_dictionary).to eq redcap_data_dictionary
      end

      it 'checks if a Redcap variable does not exist if there is no Redcap dictionary', focus: false do
        expect(redcap_project.redcap_variable_exists_in_redcap_data_dictionary?('moomin')).to be_falsey
      end

      it 'checks if a Redcap variable does not exist if there is no prior Redcap dictionary', focus: false do
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'moomin')
        expect(redcap_project.redcap_variable_exists_in_redcap_data_dictionary?('moomin')).to be_falsey
      end

      it 'checks if a Redcap variable does exist if there is a prior Redcap dictionary', focus: false do
        prior_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: prior_redcap_data_dictionary, name: 'moomin')
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        expect(redcap_project.redcap_variable_exists_in_redcap_data_dictionary?('moomin')).to be_truthy
      end

      it 'checks if a Redcap variable does not exist (because it has been deleted) if there is a prior Redcap dictionary', focus: false do
        prior_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        redcap_variable = FactoryBot.create(:redcap_variable, redcap_data_dictionary: prior_redcap_data_dictionary, name: 'moomin')
        redcap_variable.destroy!
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        expect(redcap_project.redcap_variable_exists_in_redcap_data_dictionary?('moomin')).to be_falsey
      end

      it 'checks if a Redcap variable has changed its field type if there is no Redcap dictionary', focus: false do
        expect(redcap_project.redcap_variable_field_type_changed_in_redcap_data_dictionary?('moomin', 'dropdown', nil)).to be_falsey
      end

      it 'checks if a Redcap variable has changed its field type if there is a prior Redcap dictionary', focus: false do
        prior_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: prior_redcap_data_dictionary, name: 'moomin', field_type: 'dropdown', text_validation_type: nil)
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        expect(redcap_project.redcap_variable_field_type_changed_in_redcap_data_dictionary?('moomin', 'text', nil)).to be_truthy
      end

      it 'checks if a Redcap variable has changed its field label if there is no Redcap dictionary', focus: false do
        expect(redcap_project.redcap_variable_field_label_changed_in_redcap_data_dictionary?('moomin', 'Favorite Moomin')).to be_falsey
      end

      it 'checks if a Redcap variable has changed its field label if there is a prior Redcap dictionary', focus: false do
        prior_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: prior_redcap_data_dictionary, name: 'moomin', field_label: 'Favorite Moomin?', field_type: 'dropdown', text_validation_type: nil)
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        expect(redcap_project.redcap_variable_field_label_changed_in_redcap_data_dictionary?('moomin', 'Best Moomin?')).to be_truthy
      end

      it 'checks if a Redcap variable has changed its field label if there is no Redcap dictionary', focus: false do
        expect(redcap_project.redcap_variable_choices_changed_in_redcap_data_dictionary?('clock_position_of_wound', "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")).to be_falsey
      end

      it 'checks if a Redcap variable has changed its choices if there is a prior Redcap dictionary', focus: false do
        prior_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: prior_redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create

        expect(redcap_project.redcap_variable_choices_changed_in_redcap_data_dictionary?('clock_position_of_wound', "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock")).to be_truthy
      end

      it 'checks if a Redcap variable choice does not exist if there is no Redcap dictionary', focus: false do
        expect(redcap_project.redcap_variable_choice_exists_in_redcap_data_dictionary?('clock_position_of_wound', '7')).to be_falsey
      end

      it 'checks if a Redcap variable choice does not exist if there is no prior Redcap dictionary', focus: false do
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")

        expect(redcap_project.redcap_variable_choice_exists_in_redcap_data_dictionary?('clock_position_of_wound', '1')).to be_falsey
      end

      it 'checks if a Redcap variable choice does exist if there is a prior Redcap dictionary', focus: false do
        prior_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: prior_redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        expect(redcap_project.redcap_variable_choice_exists_in_redcap_data_dictionary?('clock_position_of_wound', '1')).to be_truthy
      end

      it 'checks if a Redcap variable choice does not exist if there is a prior Redcap dictionary', focus: false do
        prior_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: prior_redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        expect(redcap_project.redcap_variable_choice_exists_in_redcap_data_dictionary?('clock_position_of_wound', '7')).to be_falsey
      end

      it 'checks if a Redcap variable choice has changed its description if there is no Redcap dictionary', focus: false do
        expect(redcap_project.redcap_variable_choice_description_changed_in_redcap_data_dictionary?('clock_position_of_wound', '7', "9 o'clock")).to be_falsey
      end

      it 'checks if a Redcap variable choice has not changed its description if there is a prior Redcap dictionary', focus: false do
        prior_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: prior_redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        expect(redcap_project.redcap_variable_choice_description_changed_in_redcap_data_dictionary?('clock_position_of_wound', '6', "8 o'clock")).to be_falsey
      end

      it 'checks if a Redcap variable choice has changed its description if there is a prior Redcap dictionary', focus: false do
        prior_redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        FactoryBot.create(:redcap_variable, redcap_data_dictionary: prior_redcap_data_dictionary, name: 'clock_position_of_wound', field_label: 'Tunneling clock position of Wound', field_type: 'dropdown', text_validation_type: nil, choices: "1, 12 o'clock | 2, 3 o'clock | 3, 6 o'clock | 4, 11 o'clock | 5, 1 o'clock| 6, 8 o'clock")
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        expect(redcap_project.redcap_variable_choice_description_changed_in_redcap_data_dictionary?('clock_position_of_wound', '6', "9 o'clock")).to be_truthy
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
