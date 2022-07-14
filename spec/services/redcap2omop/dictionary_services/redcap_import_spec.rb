require 'rails_helper'
require 'support/helpers/stub_requests'

RSpec.describe Redcap2omop::DictionaryServices::RedcapImport do
  describe 'parsing dictionary from redcap' do
    let(:redcap_project)   { FactoryBot.create(:redcap_project) }
    let(:service)   { Redcap2omop::DictionaryServices::RedcapImport.new(redcap_project: redcap_project) }
    let(:json_body) { File.read('spec/support/data/test_dictionary.json')}
    let(:json_body_with_new_redcap_variable) { File.read('spec/support/data/test_dictionary_with_new_redcap_variable.json')}
    let(:json_body_with_redcap_variable_changed_field_type) { File.read('spec/support/data/test_dictionary_with_redcap_variable_changed_field_type.json')}
    let(:json_body_with_redcap_variable_changed_field_label) { File.read('spec/support/data/test_dictionary_with_redcap_variable_changed_field_label.json')}
    let(:json_body_with_redcap_variable_add_choice) { File.read('spec/support/data/test_dictionary_with_redcap_variable_add_choice.json')}
    let(:json_body_with_redcap_variable_changed_choice_descripiton) {File.read('spec/support/data/test_dictionary_with_redcap_variable_changed_choice_descripiton.json')}
    let(:json_body_with_deleted_redcap_variable) {File.read('spec/support/data/test_dictionary_with_deleted_redcap_variable.json')}
    let(:json_body_with_deleted_redcap_variable_choice) {File.read('spec/support/data/test_dictionary_with_deleted_redcap_variable_choice.json')}
    let(:json_body_with_redcap_variable_mapped_to_omop_concept) {File.read('spec/support/data/test_dictionary_with_redcap_variable_mapped_to_omop_concept.json')}
    let(:json_body_with_redcap_variable_mapped_to_omop_concept_and_new_variable) {File.read('spec/support/data/test_dictionary_with_redcap_variable_mapped_to_omop_concept_and_new_variable.json')}
    let(:json_body_with_redcap_variable_choice_mapped_to_omop_concept) {File.read('spec/support/data/test_dictionary_with_redcap_variable_choice_mapped_to_omop_concept.json')}
    let(:json_body_with_redcap_variable_choice_mapped_to_omop_concept_and_new_variable) {File.read('spec/support/data/test_dictionary_with_redcap_variable_choice_mapped_to_omop_concept_and_new_variable.json')}
    let(:json_body_with_redcap_derived_from_base_redcap_variable_and_redcap_variable_choice_offset) {File.read('spec/support/data/test_dictionary_with_redcap_derived_from_base_redcap_variable_and_redcap_variable_choice_offset.json')}
    let(:json_body_with_redcap_derived_from_base_redcap_variable_and_redcap_variable_choice_offset_and_new_variable) {File.read('spec/support/data/test_dictionary_with_redcap_derived_from_base_redcap_variable_and_redcap_variable_choice_offset_and_new_variable.json')}
    let(:json_body_with_redcap_variable_with_child_mapped_to_an_omop_concept) {File.read('spec/support/data/test_dictionary_with_redcap_variable_with_child_mapped_to_an_omop_concept.json')}
    let(:json_body_with_redcap_variable_with_child_mapped_to_an_omop_concept_and_new_variable) {File.read('spec/support/data/test_dictionary_with_redcap_variable_with_child_mapped_to_an_omop_concept_and_new_variable.json')}
    
    
      describe 'when importing a dictianry more than onces' do
        before(:each) do
          redcap_project.api_token = Faker::Lorem.word
          stub_redcap_api_metadata_request(body: json_body)
          redcap_project.save!
        end
  
        it 'does create a new data dictionary if new Redcap variable is added', focus: true do
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload    
          stub_redcap_api_metadata_request(body: json_body_with_new_redcap_variable)
          service.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'mri_coordinator2').first
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_NEW_VARIABLE
        end
        it "does create a new data dictionary if a Redcap variable's type is changed", focus: true do
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload
          stub_redcap_api_metadata_request(body: json_body_with_redcap_variable_changed_field_type)
          service.run
        redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'moca').first
          expect(new_redcap_variable).to_not be_nil
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_TYPE
        end
        it "does create a new data dictionary if a Redcap variable's label is changed", focus: true do
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload
          stub_redcap_api_metadata_request(body: json_body_with_redcap_variable_changed_field_label)
          service.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'mri_coordinator').first
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_LABEL
        end
        it "does create a new data dictionary if a Redcap variable has a choice added", focus: true do
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload
          stub_redcap_api_metadata_request(body: json_body_with_redcap_variable_add_choice)
          service.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'clock_position_of_wound').first
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_CHOICES
        end

        it "does create a new data dictionary if a Redcap variable has a choice description changed", focus: true do
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload
          stub_redcap_api_metadata_request(body: json_body_with_redcap_variable_changed_choice_descripiton)
          service.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'clock_position_of_wound').first
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_CHOICES
          new_redcap_varaible_choice = new_redcap_variable.redcap_variable_choices.where(choice_code_raw: '5').first
          expect(new_redcap_varaible_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED_UPDATED_DESCRIPTION
        end

        it "does create a new data dictionary if a Redcap variable has been deleted", focus: true do
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload
          stub_redcap_api_metadata_request(body: json_body_with_deleted_redcap_variable)
          service.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'clock_position_of_wound').first
          old_redcap_variable = redcap_data_dictionary.redcap_variables.where(name: 'clock_position_of_wound').first
          expect(new_redcap_variable).to be_nil
          expect(old_redcap_variable.deleted_in_next_data_dictionary).to be_truthy
        end

        it "does create a new data dictionary if a Redcap variable choice has been deleted", focus: true do
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload
          stub_redcap_api_metadata_request(body: json_body_with_deleted_redcap_variable_choice)
          service.run
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
      end
      describe 'migrating maps' do
        before(:each) do
          Redcap2omop::Setup.omop_tables
          redcap_project.api_token = Faker::Lorem.word
          redcap_project.save!
        end

        it "migrates an 'OMOP column' variable map for an exisiting Redcap variable", focus: true do
          stub_redcap_api_metadata_request(body: json_body)
          service.run
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

          stub_redcap_api_metadata_request(body: json_body_with_new_redcap_variable)
          service.run
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

        it "migrates the 'skipped' curation status of a Redcap variable and leaves the curation status of Redcap variable choices alone", focus: true do
          stub_redcap_api_metadata_request(body: json_body)
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload
          old_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gender', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          old_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
          old_redcap_variable.save!

          redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Female').first
          expect(redcap_variable_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED

          redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Male').first
          expect(redcap_variable_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED

          redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Trans Female').first
          expect(redcap_variable_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED

          redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Transe Male').first
          expect(redcap_variable_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED

          redcap_variable_choice = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Non-binary').first
          expect(redcap_variable_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED

          stub_redcap_api_metadata_request(body: json_body_with_new_redcap_variable)
          service.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gender', redcap_data_dictionary_id: current_redcap_data_dictionary.id).first

          expect(new_redcap_variable.id).to_not eq old_redcap_variable.id
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
          expect(new_redcap_variable.redcap_variable_map).to be_nil

          redcap_variable_choice = new_redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Female').first
          expect(redcap_variable_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED

          redcap_variable_choice = new_redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Male').first
          expect(redcap_variable_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED

          redcap_variable_choice = new_redcap_variable.redcap_variable_choices.where(choice_description: 'Trans Female').first
          expect(redcap_variable_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED

          redcap_variable_choice = new_redcap_variable.redcap_variable_choices.where(choice_description: 'Transe Male').first
          expect(redcap_variable_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED

          redcap_variable_choice = new_redcap_variable.redcap_variable_choices.where(choice_description: 'Non-binary').first
          expect(redcap_variable_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED
        end
        it "migrates an 'OMOP concept' variable map for an exisiting Redcap variable", focus: true do
          stub_redcap_api_metadata_request(body: json_body_with_redcap_variable_mapped_to_omop_concept)
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload
          expect(redcap_data_dictionary).to_not be_nil

          old_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'wbc_range', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          wbc_concept = Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '391558003').first
          other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_d').first
          old_redcap_variable.build_redcap_variable_map(concept_id: wbc_concept.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
          old_redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          old_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          old_redcap_variable.save!

          redcap_variable_choice_1 = old_redcap_variable.redcap_variable_choices.where(choice_description: "High").first
          wbc_range_concept_1 = Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '75540009').first
          redcap_variable_choice_1.build_redcap_variable_choice_map(concept_id: wbc_range_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice_1.save!

          redcap_variable_choice_2 = old_redcap_variable.redcap_variable_choices.where(choice_description: "Low").first
          wbc_range_concept_2 = Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '62482003').first
          redcap_variable_choice_2.build_redcap_variable_choice_map(concept_id: wbc_range_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice_2.save!

          redcap_variable_choice_3 = old_redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
          wbc_range_concept_3 = Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first
          redcap_variable_choice_3.build_redcap_variable_choice_map(concept_id: wbc_range_concept_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice_3.save!

          redcap_variable_choice_4 = old_redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
          redcap_variable_choice_4.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice_4.save!

          redcap_variable_choice_5 = old_redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
          redcap_variable_choice_5.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice_5.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice_5.save!

          old_redcap_variable.save!

          stub_redcap_api_metadata_request(body: json_body_with_redcap_variable_mapped_to_omop_concept_and_new_variable)
          service.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'wbc_range', redcap_data_dictionary_id: current_redcap_data_dictionary.id).first
          expect(new_redcap_variable.id).to_not eq old_redcap_variable.id
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          expect(new_redcap_variable.redcap_variable_map.concept_id).to eq wbc_concept.id
          expect(new_redcap_variable.redcap_variable_map.omop_column_id).to be_nil
          expect(new_redcap_variable.redcap_variable_map.map_type).to eq Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT

          old_redcap_variable.redcap_variable_child_maps.each do |old_redcap_variable_child_map|
            if old_redcap_variable_child_map.redcap_variable
              new_child_map_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_variable_child_map.redcap_variable.name).first
              new_redcap_variable_child_map = new_redcap_variable.redcap_variable_child_maps.where(redcap_variable_id: new_child_map_redcap_variable.id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type)
              expect(new_redcap_variable_child_map).to_not be_nil
            end
          end
          old_redcap_variable.redcap_variable_choices.each do |old_redcap_variable_choice|
            if old_redcap_variable_choice.redcap_variable_choice_map
              new_redcap_variable_choice = new_redcap_variable.redcap_variable_choices.where(choice_code_raw: old_redcap_variable_choice.choice_code_raw).first
              expect(old_redcap_variable_choice.redcap_variable_choice_map.concept_id).to eq(new_redcap_variable_choice.redcap_variable_choice_map.concept_id)
              expect(old_redcap_variable_choice.redcap_variable_choice_map.map_type).to eq(new_redcap_variable_choice.redcap_variable_choice_map.map_type)
            end
          end
        end

        it "migrates an 'OMOP concept' variable choice map for existing Redcap variable choices", focus: true do
          stub_redcap_api_metadata_request(body: json_body_with_redcap_variable_choice_mapped_to_omop_concept)
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload

          old_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_systemic', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_d').first
          old_redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          old_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          old_redcap_variable.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

          old_redcap_variable_choice_1 = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Bleeding').first
          concept_c19_complications_systemic_1 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '43364001').first
          old_redcap_variable_choice_1.build_redcap_variable_choice_map(concept_id: concept_c19_complications_systemic_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          old_redcap_variable_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          old_redcap_variable_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          old_redcap_variable_choice_1.save!

          old_redcap_variable_choice_2 = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Disseminated intravascular coagulation (DIC)').first
          concept_c19_complications_systemic_2 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '67406007').first
          old_redcap_variable_choice_2.build_redcap_variable_choice_map(concept_id: concept_c19_complications_systemic_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          old_redcap_variable_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          old_redcap_variable_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          old_redcap_variable_choice_2.save!

          old_redcap_variable_choice_3 = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Multiorgan failure').first
          concept_c19_complications_systemic_3 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '57653000').first
          old_redcap_variable_choice_3.build_redcap_variable_choice_map(concept_id: concept_c19_complications_systemic_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          old_redcap_variable_choice_3.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          old_redcap_variable_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          old_redcap_variable_choice_3.save!

          old_redcap_variable_choice_4 = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Sepsis').first
          concept_c19_complications_systemic_4 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '91302008').first
          old_redcap_variable_choice_4.build_redcap_variable_choice_map(concept_id: concept_c19_complications_systemic_4.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          old_redcap_variable_choice_4.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          old_redcap_variable_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          old_redcap_variable_choice_4.save!

          old_redcap_variable_choice_5 = old_redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
          old_redcap_variable_choice_5.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          old_redcap_variable_choice_5.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          old_redcap_variable_choice_5.save!

          old_redcap_variable_choice_6 = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
          old_redcap_variable_choice_6.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          old_redcap_variable_choice_6.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          old_redcap_variable_choice_6.save!

          old_redcap_variable_choice_7 = old_redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
          old_redcap_variable_choice_7.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          old_redcap_variable_choice_7.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          old_redcap_variable_choice_7.save!

          stub_redcap_api_metadata_request(body: json_body_with_redcap_variable_choice_mapped_to_omop_concept_and_new_variable)
          service.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_systemic', redcap_data_dictionary_id: current_redcap_data_dictionary.id).first

          expect(new_redcap_variable.id).to_not eq old_redcap_variable.id
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          expect(new_redcap_variable.redcap_variable_map.concept_id).to be_nil
          expect(new_redcap_variable.redcap_variable_map.omop_column_id).to be_nil
          expect(new_redcap_variable.redcap_variable_map.map_type).to eq Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE
          expect(new_redcap_variable.redcap_variable_child_maps.size).to eq(0)

          test_migration_of_redcap_variable_choice_redcap_variable_child_maps(old_redcap_variable, new_redcap_variable, current_redcap_data_dictionary)
        end

        it 'migrates a Redcap child mapping to a Redcap derived date based on a base Redcap variable and a Redcap varaible choice offset', focus: true do
          stub_redcap_api_metadata_request(body: json_body_with_redcap_derived_from_base_redcap_variable_and_redcap_variable_choice_offset)
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload

          base_date_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_0', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          base_date_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
          base_date_redcap_variable.save!

          offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_dx_interval', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          offset_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
          offset_redcap_variable.save!

          redcap_variable_choices = {}
          redcap_variable_choices['Within the past week'] = 4
          redcap_variable_choices['Within the past 1 to 2 weeks'] = 11
          redcap_variable_choices['Within the past 2 to 4 weeks'] = 21
          redcap_variable_choices['Within the past 4 to 8 weeks'] = 42
          redcap_variable_choices['Within the past 8 to 12 weeks'] = 70
          redcap_variable_choices['Within the past 3 to 6 months'] = 135
          redcap_variable_choices['More than 6 months ago'] = 270
          redcap_variable_choices['Within the past 6 to 9 months'] = 225
          redcap_variable_choices['Within the past 9 to 12 months'] = 315
          redcap_variable_choices['More than 12 months ago'] = 450

          redcap_derived_date_diagnosis_covid19 = Redcap2omop::RedcapDerivedDate.where(redcap_data_dictionary: redcap_data_dictionary, name: 'COVID-19 Diagnosis', base_date_redcap_variable: base_date_redcap_variable, offset_redcap_variable: offset_redcap_variable).first_or_create

          redcap_variable_choices.each do |k,v|
            redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
            redcap_derived_date_diagnosis_covid19.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
          end
          redcap_derived_date_diagnosis_covid19.save!

          old_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dx_year', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          covid_19_concept = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first
          old_redcap_variable.build_redcap_variable_map(concept_id: covid_19_concept.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
          old_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first
          old_redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          old_redcap_variable.save!

          stub_redcap_api_metadata_request(body: json_body_with_redcap_derived_from_base_redcap_variable_and_redcap_variable_choice_offset_and_new_variable)
          service.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dx_year', redcap_data_dictionary_id: current_redcap_data_dictionary.id).first

          expect(new_redcap_variable.id).to_not eq old_redcap_variable.id
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          expect(new_redcap_variable.redcap_variable_map.concept_id).to eq covid_19_concept.id
          expect(new_redcap_variable.redcap_variable_map.omop_column_id).to be_nil
          expect(new_redcap_variable.redcap_variable_map.map_type).to eq Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT

          expect(new_redcap_variable.redcap_variable_child_maps.size).to eq(1)
          test_migration_of_redcap_variable_redcap_variable_child_maps(old_redcap_variable, new_redcap_variable, current_redcap_data_dictionary)
        end
        it 'migrates a Redcap child mapping to an OMOP concept', focus: true do
          stub_redcap_api_metadata_request(body: json_body_with_redcap_variable_with_child_mapped_to_an_omop_concept)
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload

          old_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hiv_vl', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_d').first
          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
          omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'unit_concept_id'").first
          hiv_vl_concept = Redcap2omop::Concept.where(domain_id: 'Measurement', concept_code: '413789001').first
          old_redcap_variable.build_redcap_variable_map(concept_id: hiv_vl_concept.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
          old_redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          unit_concept = Redcap2omop::Concept.where(domain_id: 'Unit', concept_code: '{copies}/mL').first
          old_redcap_variable.redcap_variable_child_maps.build(concept_id: unit_concept.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
          old_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          old_redcap_variable.save!

          stub_redcap_api_metadata_request(body: json_body_with_redcap_variable_with_child_mapped_to_an_omop_concept_and_new_variable)
          service.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hiv_vl', redcap_data_dictionary_id: current_redcap_data_dictionary.id).first

          expect(new_redcap_variable.id).to_not eq old_redcap_variable.id
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          expect(new_redcap_variable.redcap_variable_map.concept_id).to eq hiv_vl_concept.id
          expect(new_redcap_variable.redcap_variable_map.omop_column_id).to be_nil
          expect(new_redcap_variable.redcap_variable_map.map_type).to eq Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT

          expect(new_redcap_variable.redcap_variable_child_maps.size).to eq(2)
          test_migration_of_redcap_variable_redcap_variable_child_maps(old_redcap_variable, new_redcap_variable, current_redcap_data_dictionary)
        end
      end

      describe 'when import is successful' do
        before(:each) do
          redcap_project.api_token = Faker::Lorem.word
          redcap_project.save!
        end
        it 'creates redcap variables', focus: true do
          stub_redcap_api_metadata_request(body: json_body)
          expect(Redcap2omop::RedcapVariable.count).to eq 0
          expect{ service.run }.to change{ Redcap2omop::RedcapVariable.count }.by(39)
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

        it 'returns success' do
          stub_redcap_api_metadata_request(body: json_body)
          expect(service.run.success).to eq true
        end
      end

      context 'when import fails' do
        it 'raises error if project API token is blank' do
          redcap_project.api_token = nil
          result = service.run
          expect(result.success).to eq false
          expect(result.message).to eq 'project api token is missing'
        end

        it 'raises error if retrieving data fails' do
          redcap_project.api_token = Faker::Lorem.word
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
          redcap_project.api_token = Faker::Lorem.word
          stub_redcap_api_metadata_request(body: json_body)
          expect(service.run.message).to eq 'Validation failed: '
        end
        it 'returns exception' do
          stub_redcap_api_metadata_request(body: json_body)
          result = service.run
          expect(result.success).to eq false
          expect(result.message).not_to be_blank
          expect(result.backtrace).not_to be_blank
        end
      end
    end
  end

def test_migration_of_redcap_variable_redcap_variable_child_maps(old_redcap_variable, new_redcap_variable, current_redcap_data_dictionary)
  old_redcap_variable.redcap_variable_child_maps.each do |old_redcap_variable_child_map|
    if old_redcap_variable_child_map.redcap_variable
      new_child_map_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_variable_child_map.redcap_variable.name).first
      new_redcap_variable_child_map = new_redcap_variable.redcap_variable_child_maps.where(redcap_variable_id: new_child_map_redcap_variable.id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
      expect(new_redcap_variable_child_map).to_not be_nil
    end

    if old_redcap_variable_child_map.redcap_derived_date
      old_redcap_derived_date = Redcap2omop::RedcapDerivedDate.find(old_redcap_variable_child_map.redcap_derived_date_id)
      if old_redcap_derived_date.base_date_redcap_variable
        old_redcap_derived_date = Redcap2omop::RedcapDerivedDate.find(old_redcap_variable_child_map.redcap_derived_date_id)
        new_base_date_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.base_date_redcap_variable.name).first
        new_offset_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.offset_redcap_variable.name).first
        new_redcap_derived_date = current_redcap_data_dictionary.redcap_derived_dates.where(name: old_redcap_derived_date.name, base_date_redcap_variable_id: new_base_date_redcap_variable.id, offset_redcap_variable_id: new_offset_redcap_variable.id).first
        new_redcap_variable_child_map = new_redcap_variable.redcap_variable_child_maps.where(redcap_derived_date_id: new_redcap_derived_date.id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
        expect(new_redcap_variable_child_map).to_not be_nil
      end

      if old_redcap_derived_date.parent_redcap_derived_date
        new_parent_redcap_derived_date = current_redcap_data_dictionary.redcap_derived_dates.where(name: old_redcap_derived_date.parent_redcap_derived_date.name).first
        new_offset_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.offset_redcap_variable.name).first
        new_redcap_derived_date = current_redcap_data_dictionary.redcap_derived_dates.where(name: old_redcap_derived_date.name, parent_redcap_derived_date_id: new_parent_redcap_derived_date.id, offset_redcap_variable_id: new_offset_redcap_variable.id).first
        new_redcap_variable_child_map = new_redcap_variable.redcap_variable_child_maps.where(redcap_derived_date_id: new_redcap_derived_date.id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
        expect(new_redcap_variable_child_map).to_not be_nil
      end

      expect(new_redcap_derived_date.redcap_derived_date_choice_offset_mappings.size).to eq(old_redcap_derived_date.redcap_derived_date_choice_offset_mappings.size)
      old_redcap_derived_date.redcap_derived_date_choice_offset_mappings.each do |old_redcap_derived_date_choice_offset_mapping|
        new_redcap_variable_choice = new_offset_redcap_variable.redcap_variable_choices.where(choice_code_raw: old_redcap_derived_date_choice_offset_mapping.redcap_variable_choice.choice_code_raw).first
        new_redcap_derived_date_choice_offset_mapping = new_redcap_derived_date.redcap_derived_date_choice_offset_mappings.where(redcap_variable_choice_id: new_redcap_variable_choice.id, offset_days: old_redcap_derived_date_choice_offset_mapping.offset_days).first
        expect(new_redcap_derived_date_choice_offset_mapping).to_not be_nil
      end
    end

    if old_redcap_variable_child_map.concept_id
      new_redcap_variable_child_map = new_redcap_variable.redcap_variable_child_maps.where(concept_id: old_redcap_variable_child_map.concept_id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
      expect(new_redcap_variable_child_map).to_not be_nil
    end
  end
end

def test_migration_of_redcap_variable_choice_redcap_variable_child_maps(old_redcap_variable, new_redcap_variable, current_redcap_data_dictionary)
  old_redcap_variable.redcap_variable_choices.each do |old_redcap_variable_choice|
    new_redcap_variable_choice = new_redcap_variable.redcap_variable_choices.where(choice_code_raw: old_redcap_variable_choice.choice_code_raw).first
    expect(new_redcap_variable_choice.curation_status).to eq(old_redcap_variable_choice.curation_status)
    expect(new_redcap_variable_choice.redcap_variable_choice_map.concept_id).to eq(old_redcap_variable_choice.redcap_variable_choice_map.concept_id)
    expect(new_redcap_variable_choice.redcap_variable_choice_map.map_type).to eq(old_redcap_variable_choice.redcap_variable_choice_map.map_type)
    old_redcap_variable_choice.redcap_variable_child_maps.each do |old_redcap_variable_child_map|
      if old_redcap_variable_child_map.redcap_variable
        new_child_map_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_variable_child_map.redcap_variable.name).first
        new_redcap_variable_child_map = new_redcap_variable_choice.redcap_variable_child_maps.where(redcap_variable_id: new_child_map_redcap_variable.id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
        expect(new_redcap_variable_child_map).to_not be_nil
      end

      if old_redcap_variable_child_map.redcap_derived_date
        old_redcap_derived_date = Redcap2omop::RedcapDerivedDate.find(old_redcap_variable_child_map.redcap_derived_date_id)

        if old_redcap_derived_date.base_date_redcap_variable
          new_base_date_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.base_date_redcap_variable.name).first
          new_offset_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.offset_redcap_variable.name).first
          new_redcap_derived_date = current_redcap_data_dictionary.redcap_derived_dates.where(name: old_redcap_derived_date.name, base_date_redcap_variable_id: new_base_date_redcap_variable.id, offset_redcap_variable_id: new_offset_redcap_variable.id).first
          new_redcap_variable_child_map = new_redcap_variable_choice.redcap_variable_child_maps.where(redcap_derived_date_id: new_redcap_derived_date.id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
          expect(new_redcap_variable_child_map).to_not be_nil
        end

        if old_redcap_derived_date.parent_redcap_derived_date
          new_parent_redcap_derived_date = current_redcap_data_dictionary.redcap_derived_dates.where(name: old_redcap_derived_date.parent_redcap_derived_date.name).first
          new_offset_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.offset_redcap_variable.name).first
          new_redcap_derived_date = current_redcap_data_dictionary.redcap_derived_dates.where(name: old_redcap_derived_date.name, parent_redcap_derived_date_id: new_parent_redcap_derived_date.id, offset_redcap_variable_id: new_offset_redcap_variable.id).first
          new_redcap_variable_child_map = new_redcap_variable_choice.redcap_variable_child_maps.where(redcap_derived_date_id: new_redcap_derived_date.id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
          expect(new_redcap_variable_child_map).to_not be_nil
        end

        expect(new_redcap_derived_date.redcap_derived_date_choice_offset_mappings.size).to eq(old_redcap_derived_date.redcap_derived_date_choice_offset_mappings.size)
        old_redcap_derived_date.redcap_derived_date_choice_offset_mappings.each do |old_redcap_derived_date_choice_offset_mapping|
          new_redcap_variable_choice_for_choice_offset_mapping = new_offset_redcap_variable.redcap_variable_choices.where(choice_code_raw: old_redcap_derived_date_choice_offset_mapping.redcap_variable_choice.choice_code_raw).first
          new_redcap_derived_date_choice_offset_mapping = new_redcap_derived_date.redcap_derived_date_choice_offset_mappings.where(redcap_variable_choice_id: new_redcap_variable_choice_for_choice_offset_mapping.id, offset_days: old_redcap_derived_date_choice_offset_mapping.offset_days).first
          expect(new_redcap_derived_date_choice_offset_mapping).to_not be_nil
        end
      end

      if old_redcap_variable_child_map.concept_id
        new_redcap_variable_child_map = new_redcap_variable_choice.redcap_variable_child_maps.where(concept_id: old_redcap_variable_child_map.concept_id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
        expect(new_redcap_variable_child_map).to_not be_nil
      end
    end
  end
end

def test_migration_of_redcap_variable_choice_redcap_variable_child_maps(old_redcap_variable, new_redcap_variable, current_redcap_data_dictionary)
  old_redcap_variable.redcap_variable_choices.each do |old_redcap_variable_choice|
    new_redcap_variable_choice = new_redcap_variable.redcap_variable_choices.where(choice_code_raw: old_redcap_variable_choice.choice_code_raw).first
    expect(new_redcap_variable_choice.curation_status).to eq(old_redcap_variable_choice.curation_status)
    expect(new_redcap_variable_choice.redcap_variable_choice_map.concept_id).to eq(old_redcap_variable_choice.redcap_variable_choice_map.concept_id)
    expect(new_redcap_variable_choice.redcap_variable_choice_map.map_type).to eq(old_redcap_variable_choice.redcap_variable_choice_map.map_type)
    old_redcap_variable_choice.redcap_variable_child_maps.each do |old_redcap_variable_child_map|
      if old_redcap_variable_child_map.redcap_variable
        new_child_map_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_variable_child_map.redcap_variable.name).first
        new_redcap_variable_child_map = new_redcap_variable_choice.redcap_variable_child_maps.where(redcap_variable_id: new_child_map_redcap_variable.id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
        expect(new_redcap_variable_child_map).to_not be_nil
      end

      if old_redcap_variable_child_map.redcap_derived_date
        old_redcap_derived_date = Redcap2omop::RedcapDerivedDate.find(old_redcap_variable_child_map.redcap_derived_date_id)

        if old_redcap_derived_date.base_date_redcap_variable
          new_base_date_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.base_date_redcap_variable.name).first
          new_offset_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.offset_redcap_variable.name).first
          new_redcap_derived_date = current_redcap_data_dictionary.redcap_derived_dates.where(name: old_redcap_derived_date.name, base_date_redcap_variable_id: new_base_date_redcap_variable.id, offset_redcap_variable_id: new_offset_redcap_variable.id).first
          new_redcap_variable_child_map = new_redcap_variable_choice.redcap_variable_child_maps.where(redcap_derived_date_id: new_redcap_derived_date.id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
          expect(new_redcap_variable_child_map).to_not be_nil
        end

        if old_redcap_derived_date.parent_redcap_derived_date
          new_parent_redcap_derived_date = current_redcap_data_dictionary.redcap_derived_dates.where(name: old_redcap_derived_date.parent_redcap_derived_date.name).first
          new_offset_redcap_variable = current_redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.offset_redcap_variable.name).first
          new_redcap_derived_date = current_redcap_data_dictionary.redcap_derived_dates.where(name: old_redcap_derived_date.name, parent_redcap_derived_date_id: new_parent_redcap_derived_date.id, offset_redcap_variable_id: new_offset_redcap_variable.id).first
          new_redcap_variable_child_map = new_redcap_variable_choice.redcap_variable_child_maps.where(redcap_derived_date_id: new_redcap_derived_date.id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
          expect(new_redcap_variable_child_map).to_not be_nil
        end

        expect(new_redcap_derived_date.redcap_derived_date_choice_offset_mappings.size).to eq(old_redcap_derived_date.redcap_derived_date_choice_offset_mappings.size)
        old_redcap_derived_date.redcap_derived_date_choice_offset_mappings.each do |old_redcap_derived_date_choice_offset_mapping|
          new_redcap_variable_choice_for_choice_offset_mapping = new_offset_redcap_variable.redcap_variable_choices.where(choice_code_raw: old_redcap_derived_date_choice_offset_mapping.redcap_variable_choice.choice_code_raw).first
          new_redcap_derived_date_choice_offset_mapping = new_redcap_derived_date.redcap_derived_date_choice_offset_mappings.where(redcap_variable_choice_id: new_redcap_variable_choice_for_choice_offset_mapping.id, offset_days: old_redcap_derived_date_choice_offset_mapping.offset_days).first
          expect(new_redcap_derived_date_choice_offset_mapping).to_not be_nil
        end
      end

      if old_redcap_variable_child_map.concept_id
        new_redcap_variable_child_map = new_redcap_variable_choice.redcap_variable_child_maps.where(concept_id: old_redcap_variable_child_map.concept_id, omop_column_id: old_redcap_variable_child_map.omop_column_id, map_type: old_redcap_variable_child_map.map_type).first
        expect(new_redcap_variable_child_map).to_not be_nil
      end
    end
  end
end
