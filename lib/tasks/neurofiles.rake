namespace :redcap2omop do
  namespace :setup do
    namespace :neurofiles do
    desc 'setup Neurofiles projects'
    task projects: :environment do |t, args|
      redcap_project = Redcap2omop::RedcapProject.where(project_id: 5840).first_or_initialize
      redcap_project.name                 = 'Data Migration Sandbox - CorePID'
      redcap_project.insert_person        = true
      redcap_project.api_import           = true
      redcap_project.route_to_observation = true
      redcap_project.save!

      redcap_project = Redcap2omop::RedcapProject.where(project_id: 5843).first_or_initialize
      redcap_project.name                 = 'Data Migration Sandbox -- PPA'
      redcap_project.insert_person        = true
      redcap_project.api_import           = true
      redcap_project.route_to_observation = true
      redcap_project.save!

      redcap_project = Redcap2omop::RedcapProject.where(project_id: 5844).first_or_initialize
      redcap_project.name                 = 'Data Migration Sandbox - SA'
      redcap_project.insert_person        = true
      redcap_project.api_import           = true
      redcap_project.route_to_observation = true
      redcap_project.save!
    end

    desc "setup mappings for neurofiles"
    task maps: :environment do |t, args|
      redcap_project          = Redcap2omop::RedcapProject.where(project_id: 5840).first
      redcap_data_dictionary  = Redcap2omop::RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
      Redcap2omop::RedcapVariableMap.joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
      Redcap2omop::RedcapVariableChoiceMap.joins(redcap_variable_choice: :redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
      Redcap2omop::RedcapVariableChildMap.joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all

      redcap_project          = Redcap2omop::RedcapProject.where(project_id: 5843).first
      redcap_data_dictionary  = Redcap2omop::RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
      Redcap2omop::RedcapVariableMap.joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
      Redcap2omop::RedcapVariableChoiceMap.joins(redcap_variable_choice: :redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
      Redcap2omop::RedcapVariableChildMap.joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all

      redcap_project          = Redcap2omop::RedcapProject.where(project_id: 5844).first
      redcap_data_dictionary  = Redcap2omop::RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
      Redcap2omop::RedcapVariableMap.joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
      Redcap2omop::RedcapVariableChoiceMap.joins(redcap_variable_choice: :redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
      Redcap2omop::RedcapVariableChildMap.joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all

      map_core
      map_ppa
      map_sa
    end

    desc 'setup Neurofiles sandbox project'
    task project_sandbox: :environment do |t, args|
      redcap_project = Redcap2omop::RedcapProject.where(project_id: 5912).first_or_initialize
      redcap_project.name                 = 'REDCap2SQL -- sandbox 2 - Longitudinal'
      redcap_project.api_import           = true
      redcap_project.insert_person        = true
      redcap_project.route_to_observation = false
      redcap_project.save!
    end

    desc "setup mappings for neurofiles sandbox"
    task maps_sandbox: :environment do |t, args|
      redcap_project          = Redcap2omop::RedcapProject.where(name: 'REDCap2SQL -- sandbox 2 - Longitudinal').first
      redcap_data_dictionary  = Redcap2omop::RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))

      Redcap2omop::RedcapVariableMap.joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
      Redcap2omop::RedcapVariableChoiceMap.joins(redcap_variable_choice: :redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
      Redcap2omop::RedcapVariableChildMap.joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all

      #patient
      redcap_variable = Redcap2omop::RedcapVariable.where(name: 'record_id', redcap_data_dictionary_id: redcap_data_dictionary.id).first
      omop_column     = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'person_source_value'").first
      redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
      redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
      redcap_variable.save!

      redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gender', redcap_data_dictionary_id: redcap_data_dictionary.id).first
      omop_column     = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'gender_concept_id'").first
      redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
      redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Female').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'F').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Male').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'M').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Trans Female').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: 0)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Transe Male').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: 0)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Non-binary').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: 0)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dob', redcap_data_dictionary_id: redcap_data_dictionary.id).first
      omop_column     = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'birth_datetime'").first
      redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
      redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
      redcap_variable.save!

      redcap_variable = Redcap2omop::RedcapVariable.where(name: 'race', redcap_data_dictionary_id: redcap_data_dictionary.id).first
      omop_column     = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'race_concept_id'").first
      redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
      redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'American Indian or Alaska Native').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '1').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Asian').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '2').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Black or African American').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '3').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic or Latino').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: 0)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Native Hawaiian or Other Pacific Islander').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '4').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'White').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '5').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: 0)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ethnicity', redcap_data_dictionary_id: redcap_data_dictionary.id).first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'ethnicity_concept_id'").first
      redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
      redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic or Latino').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Hispanic').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not Hispanic or Latino').first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      #provider
      redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_coordinator', redcap_data_dictionary_id: redcap_data_dictionary.id).first
      omop_column       = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_source_value'").first
      other_omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_name'").first
      redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
      redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: redcap_variable, omop_column: other_omop_column)
      redcap_variable.save!

      #moca
      redcap_variable = Redcap2omop::RedcapVariable.where(name: 'moca', redcap_data_dictionary_id: redcap_data_dictionary.id).first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '72172-0').first.concept_id)
      redcap_variable.save!

      other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_d').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_coordinator').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #mood
      redcap_variable = Redcap2omop::RedcapVariable.where(name: 'mood', redcap_data_dictionary_id: redcap_data_dictionary.id).first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '66773-3').first.concept_id)
      redcap_variable.save!

      other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_d').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_coordinator').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #clock_position_of_wound
      redcap_variable = Redcap2omop::RedcapVariable.where(name: 'clock_position_of_wound', redcap_data_dictionary_id: redcap_data_dictionary.id).first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', concept_code: '72297-5').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 o'clock").first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19054-8').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "11 o'clock").first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19057-1').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "12 o'clock").first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19055-5').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 o'clock").first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19053-0').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 o'clock").first
      redcap_variable_choice.build_redcap_variable_choice_map(map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT, concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19056-3').first.concept_id)
      redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
      redcap_variable_choice.save!

      other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_d', redcap_data_dictionary_id: redcap_data_dictionary.id).first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_coordinator', redcap_data_dictionary_id: redcap_data_dictionary.id).first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!
    end

    desc "Insert people"
    task(insert_people: :environment) do |t, args|
      person = Person.new
      person.person_id = Person.next_id
      person.gender_concept_id = 0
      person.birth_datetime = DateTime.parse('1976-10-14')
      person.race_concept_id = 0
      person.ethnicity_concept_id = 0
      person.person_source_value = 'abc123'
      person.save!
    end
    end
  end
end
