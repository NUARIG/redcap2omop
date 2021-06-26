require 'rails_helper'

RSpec.describe Redcap2omop::DictionaryServices::CsvImport do
  describe 'parsing dictionary from CSV file' do
    let(:redcap_project) { FactoryBot.create(:redcap_project) }
    let(:import) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: redcap_project,
        csv_file: 'spec/support/data/test_dictionary.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }

    let(:import_data_dictionary_with_new_redcap_variable) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: redcap_project,
        csv_file: 'spec/support/data/test_dictionary_with_new_redcap_variable.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }

    let(:import_data_dictionary_with_redcap_variable_changed_field_type) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: redcap_project,
        csv_file: 'spec/support/data/test_dictionary_with_redcap_variable_changed_field_type.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }

    let(:import_data_dictionary_with_redcap_variable_changed_field_label) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: redcap_project,
        csv_file: 'spec/support/data/test_dictionary_with_redcap_variable_changed_field_label.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }

    let(:import_data_dictionary_with_redcap_variable_add_choice) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: redcap_project,
        csv_file: 'spec/support/data/test_dictionary_with_redcap_variable_add_choice.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }

    let(:import_data_dictionary_with_redcap_variable_changed_choice_descripiton) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: redcap_project,
        csv_file: 'spec/support/data/test_dictionary_with_redcap_variable_change_choice_description.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }

    let(:import_data_dictionary_with_deleted_redcap_variable) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: redcap_project,
        csv_file: 'spec/support/data/test_dictionary_with_deleted_redcap_variable.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }

    let(:import_data_dictionary_with_deleted_redcap_variable_choice) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: redcap_project,
        csv_file: 'spec/support/data/test_dictionary_with_deleted_redcap_variable_choice.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }

    describe 'when import is successful' do
      it 'creates new dictionary', focus: false do
        expect{ import.run }.to change{ Redcap2omop::RedcapDataDictionary.count }.by(1)
        expect(Redcap2omop::RedcapDataDictionary.last.redcap_project).to eq redcap_project
      end

      it 'creates redcap variables' do
        expect(Redcap2omop::RedcapVariable.count).to eq 0
        expect{ import.run }.to change{ Redcap2omop::RedcapVariable.count }.by(18)
        Redcap2omop::RedcapVariable.all.each do |redcap_variable|
          expect(redcap_variable.redcap_data_dictionary.redcap_project).to eq redcap_project
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

      it 'returns success', focus: false do
        expect(import.run.success).to eq true
      end

      it 'does not create a new data dictionary if nothing changed', focus: false do
        import.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        import.run
        redcap_project.reload
        expect(redcap_project.current_redcap_data_dictionary).to eq redcap_data_dictionary
      end

      it 'does create a new data dictionary if new Redcap variable is added', focus: false do
        import.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        import_data_dictionary_with_new_redcap_variable.run
        redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
        expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'mri_coordinator2').first
        expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_NEW_VARIABLE
      end

      it "does create a new data dictionary if a Redcap variable's type is changed", focus: false do
        import.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        import_data_dictionary_with_redcap_variable_changed_field_type.run
        redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
        expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'moca').first
        expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_TYPE
      end

      it "does create a new data dictionary if a Redcap variable's label is changed", focus: false do
        import.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        import_data_dictionary_with_redcap_variable_changed_field_label.run
        redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
        expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'mri_coordinator').first
        expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_LABEL
      end

      it "does create a new data dictionary if a Redcap variable has a choice added", focus: false do
        import.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        import_data_dictionary_with_redcap_variable_add_choice.run
        redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
        expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'clock_position_of_wound').first
        expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_CHOICES
        new_redcap_varaible_choice = new_redcap_variable.redcap_variable_choices.where(choice_code_raw: '6').first
        expect(new_redcap_varaible_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED_NEW_CHOICE
      end

      it "does create a new data dictionary if a Redcap variable has a choice description changed", focus: false do
        import.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        import_data_dictionary_with_redcap_variable_changed_choice_descripiton.run
        redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
        expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'clock_position_of_wound').first
        expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_CHOICES
        new_redcap_varaible_choice = new_redcap_variable.redcap_variable_choices.where(choice_code_raw: '5').first
        expect(new_redcap_varaible_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED_UPDATED_DESCRIPTION
      end

      it "does create a new data dictionary if a Redcap variable has been deleted", focus: false do
        import.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        import_data_dictionary_with_deleted_redcap_variable.run
        redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
        expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'clock_position_of_wound').first
        old_redcap_variable = redcap_data_dictionary.redcap_variables.where(name: 'clock_position_of_wound').first
        expect(new_redcap_variable).to be_nil
        expect(old_redcap_variable.deleted_in_next_data_dictionary).to be_truthy
      end

      it "does create a new data dictionary if a Redcap variable choice has been deleted", focus: false do
        import.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        import_data_dictionary_with_deleted_redcap_variable_choice.run
        redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
        expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'clock_position_of_wound').first
        old_redcap_variable = redcap_data_dictionary.redcap_variables.where(name: 'clock_position_of_wound').first
        deleted_old_redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_code_raw: '5').first
        not_deletdd_redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_code_raw: '4').first
        expect(deleted_old_redcap_variable_choice.deleted_in_next_data_dictionary).to be_truthy
        expect(not_deletdd_redcap_variable_choice.deleted_in_next_data_dictionary).to be_falsey
      end

      describe 'migrating maps' do
        before(:each) do
          Redcap2omop::Setup.omop_tables
        end

        it "migrates a 'OMOP column' variable map for an exisiting Redcap variable", focus: false do
          import.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload
          old_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gender', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'gender_concept_id'").first
          old_redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
          old_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          old_redcap_variable.save!

          redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Female').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'F').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Male').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'M').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Trans Female').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Transe Male').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Non-binary').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          import_data_dictionary_with_new_redcap_variable.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gender', redcap_data_dictionary_id: current_redcap_data_dictionary.id).first

          expect(new_redcap_variable.id).to_not eq old_redcap_variable.id
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          expect(new_redcap_variable.redcap_variable_map.omop_column_id).to eq omop_column.id
          expect(new_redcap_variable.redcap_variable_map.concept_id).to be_nil
          expect(new_redcap_variable.redcap_variable_map.map_type).to eq Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN
        end
      end
    end

    context 'when import fails' do
      before(:each) do
        allow_any_instance_of(Redcap2omop::RedcapVariable).to receive(:valid?).and_return(false)
      end

      it 'does not save new dictionary' do
        expect{ import.run }.not_to change{ Redcap2omop::RedcapDataDictionary.count }
      end

      it 'does not create redcap variables' do
        expect{ import.run }.not_to change{ Redcap2omop::RedcapVariable.count }
      end

      it 'returns exception' do
        result = import.run
        expect(result.success).to eq false
        expect(result.message).not_to be_blank
        expect(result.backtrace).not_to be_blank
      end
    end
  end
end
