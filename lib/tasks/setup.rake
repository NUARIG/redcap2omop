namespace :redcap2omop do
  namespace :setup do
    desc "OMOP tables"
    task(omop_tables: :environment) do |t, args|
      Redcap2omop::OmopTable.delete_all
      Redcap2omop::OmopColumn.delete_all

      [Redcap2omop::Person, Redcap2omop::Provider, Redcap2omop::Observation, Redcap2omop::Measurement].map(&:setup_omop_table)
    end

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
        redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
        redcap_variable.save!

        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gender', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column     = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'gender_concept_id'").first
        redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Female').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'F').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Male').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'M').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Trans Female').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Transe Male').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Non-binary').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
        redcap_variable_choice.save!

        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dob', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column     = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'birth_datetime'").first
        redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
        redcap_variable.save!

        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'race', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column     = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'race_concept_id'").first
        redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'American Indian or Alaska Native').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '1').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Asian').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '2').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Black or African American').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '3').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic or Latino').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Native Hawaiian or Other Pacific Islander').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '4').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'White').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '5').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
        redcap_variable_choice.save!

        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ethnicity', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'ethnicity_concept_id'").first
        redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic or Latino').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Hispanic').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not Hispanic or Latino').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id)
        redcap_variable_choice.save!

        #provider
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_coordinator', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column       = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_source_value'").first
        other_omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_name'").first
        redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
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
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19054-8').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "11 o'clock").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19057-1').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "12 o'clock").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19055-5').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 o'clock").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19053-0').first.concept_id)
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 o'clock").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19056-3').first.concept_id)
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
    end

    namespace :ccc19 do
      desc 'setup CCC19 project'
      task project: :environment do  |t, args|
        redcap_project = Redcap2omop::RedcapProject.where(project_id: 0 , name: 'CCC19', api_import: false).first_or_create
        file_name = 'CCC19_DataDictionary.csv'
        file_location = "#{Rails.root}/lib/setup/data/data_dictionaries/"
        data_dictionary = File.read("#{file_location}#{file_name}")
        data_dictionary[0]=''
        File.write("#{file_location}CCC19_DataDictionary_clean.csv", data_dictionary)
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

    def map_core
      #REDCap Project: Data Migration Sandbox - Core
      # redcap_project          = Redcap2omop::RedcapProject.where(name: 'Data Migration Sandbox - Core').first
      redcap_project          = Redcap2omop::RedcapProject.where(project_id: 5840).first
      redcap_data_dictionary  = Redcap2omop::RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
      redcap_variables        = redcap_data_dictionary.redcap_variables

      # patient
      redcap_variable = redcap_variables.where(name: 'global_id').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'person_source_value'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable = redcap_variables.where(name: 'sex_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'gender_concept_id'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Female').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'F').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Male').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'M').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prefer not to answer').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable = redcap_variables.where(name: 'birthyr').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'year_of_birth'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable = redcap_variables.where(name: 'dob_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'birth_datetime'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable = redcap_variables.where(name: 'race_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'race_concept_id'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'White').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '5').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Black or African American').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '3').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'American Indian or Alaska Native').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '1').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Native Hawaiian or Other Pacific Islander').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '4').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Asian').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '2').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other (specify)').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prefer not to answer').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable = redcap_variables.where(name: 'ethnicity_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'ethnicity_concept_id'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not Hispanic').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Hispanic').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prefer not to answer').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      #provider
      redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column       = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_source_value'").first
      other_omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_name'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: redcap_variable, omop_column: other_omop_column)
      redcap_variable.save!

      redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column       = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_source_value'").first
      other_omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_name'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: redcap_variable, omop_column: other_omop_column)
      redcap_variable.save!

      redcap_variable = redcap_variables.where(name: 'netid_t1').first
      omop_column       = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_source_value'").first
      other_omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_name'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: redcap_variable, omop_column: other_omop_column)
      redcap_variable.save!

      #primlang
      redcap_variable = redcap_variables.where(name: 'primlang').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'Language_SpokenWrittenLanguage', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 English").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_EnglishUnitedStates', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Spanish").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_SpanishSpain', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Mandarin").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Cantonese").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Russian").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_RussianRussia', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Japanese").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_Japanese').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '8 Other primary language (specify)').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA46-8').first.concept_id)
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "9 Unknown").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #primlanx
      redcap_variable = redcap_variables.where(name: 'primlanx').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'Language_SpokenWrittenLanguage', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #educ
      redcap_variable = redcap_variables.where(name: 'educ').first
      redcap_variable.field_type_curated = 'integer'
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '82590-1', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '99 = Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #mc_subject_occupation
      redcap_variable = redcap_variables.where(name: 'mc_subject_occupation').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '14679004', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #maristat
      redcap_variable = redcap_variables.where(name: 'maristat').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '45404-1', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Married").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA48-4', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Widowed").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA49-2', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Divorced").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA51-8', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Separated").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4288-2', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Never married (or marriage was annulled)").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA47-6', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Living as married/domestic partner").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA15605-1').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #handed
      redcap_variable = redcap_variables.where(name: 'handed').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '57427004', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Left-handed").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '87683000', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Right-handed").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '46669005', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Ambidextrous").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '46669005', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #residenc
      redcap_variable = redcap_variables.where(name: 'residenc').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '334381000000106', standard_concept: 'S').first.concept_id) #Residence and accommodation circumstances
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Single - or multi-family private residence (apartment, condo, house)").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA10062-0', standard_concept: 'S').first.concept_id) # Private residence
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Retirement community or independent group living").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Assisted living, adult family home, or boarding home").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Skilled nursing facility, nursing home, hospital, or hospice").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #livsitua
      redcap_variable = redcap_variables.where(name: 'livsitua').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '365481000', standard_concept: 'S').first.concept_id) # does not fully match
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Lives alone").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '105529008', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Lives with one other person: a spouse or partner").first
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '408821002', standard_concept: 'S').first.concept_id) # lives with partner
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '447051007', standard_concept: 'S').first.concept_id) # lives with spouse
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Lives with one other person: a relative, friend, or roommate").first
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '430793000', standard_concept: 'S').first.concept_id) # lives with roommate
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'LOINC', concept_code: 'LP97141-3').first.concept_id) # Patient lives with other person
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Lives with caregiver who is not spouse/partner, relative, or friend").first
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '224498006', standard_concept: 'S').first.concept_id) # lives with caregiver
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Lives with a group (related or not related) in a private residence").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Lives in group home (e.g., assisted living, nursing home, convent)").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      # mc_subject_driving
      redcap_variable = redcap_variables.where(name: 'mc_subject_driving').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '129060000', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "0 No").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA32-8').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Yes").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA33-6').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "8 Never drove").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA15728-1').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      # mc_stop_driving
      redcap_variable = redcap_variables.where(name: 'mc_stop_driving').first
      redcap_variable.field_type_curated = 'integer'
      redcap_variable.redcap_variable_maps.build(concept_id: 0)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '999 = Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      # mc_car_accident
      redcap_variable = redcap_variables.where(name: 'mc_car_accident').first
      redcap_variable.redcap_variable_maps.build(concept_id: 0)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "0 No").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA32-8').first.concept_id) # Patient lives with other person
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Yes").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA33-6').first.concept_id) # Patient lives with other person
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      # mc_number_accidents
      redcap_variable = redcap_variables.where(name: 'mc_number_accidents').first
      redcap_variable.field_type_curated = 'integer'
      redcap_variable.redcap_variable_maps.build(concept_id: 0)
      redcap_variable.save!

      # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '999 = Unknown').first
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      # redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'formdate_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_a1').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!
    end

    def map_ppa
      #REDCap Project: Data Migration Sandbox -- PPA
      # redcap_project          = Redcap2omop::RedcapProject.where(name: 'Data Migration Sandbox -- PPA').first
      redcap_project          = Redcap2omop::RedcapProject.where(project_id: 5843).first
      redcap_data_dictionary  = Redcap2omop::RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
      redcap_variables        = redcap_data_dictionary.redcap_variables

      redcap_variable = redcap_variables.where(name: 'global_id').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'person_source_value'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable = redcap_variables.where(name: 'sex_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'gender_concept_id'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Female').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'F').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Male').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'M').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prefer not to answer').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable = redcap_variables.where(name: 'dob_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'birth_datetime'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable = redcap_variables.where(name: 'race_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'race_concept_id'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'White').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '5').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Black or African American').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '3').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'American Indian or Alaska Native').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '1').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Native Hawaiian or Other Pacific Islander').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '4').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Asian').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '2').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other (specify)').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prefer not to answer').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable = redcap_variables.where(name: 'ethnicity_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'ethnicity_concept_id'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not Hispanic').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Hispanic').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prefer not to answer').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      #provider
      redcap_variable = redcap_variables.where(name: 'netid_summary').first
      omop_column       = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_source_value'").first
      other_omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_name'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: redcap_variable, omop_column: other_omop_column)
      redcap_variable.save!

      #primlang
      redcap_variable = redcap_variables.where(name: 'primlang').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'Language_SpokenWrittenLanguage', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 English").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_EnglishUnitedStates', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Spanish").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_SpanishSpain', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Mandarin").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Cantonese").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Russian").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_RussianRussia', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Japanese").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_Japanese').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '8 Other primary language (specify)').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA46-8').first.concept_id)
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "9 Unknown").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'visit_date_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #primlangx
      redcap_variable = redcap_variables.where(name: 'primlanx').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'Language_SpokenWrittenLanguage', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'visit_date_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #educ
      redcap_variable = redcap_variables.where(name: 'educ').first
      redcap_variable.field_type_curated = 'integer'
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '82590-1', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '99 = Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'visit_date_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #highestdegree_patient
      redcap_variable = redcap_variables.where(name: 'highestdegree_patient').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '82589-3', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'visit_date_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #mc_subject_occupation
      redcap_variable = redcap_variables.where(name: 'mc_subject_occupation').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '14679004', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'visit_date_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #maristat
      redcap_variable = redcap_variables.where(name: 'maristat').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '45404-1', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Married").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA48-4', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Widowed").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA49-2', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Divorced").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA51-8', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Separated").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4288-2', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Never married (or marriage was annulled)").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA47-6', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Living as married/domestic partner").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA15605-1').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'visit_date_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid_summary').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!


      # edinburghhandedness
      # redcap_variable = redcap_variables.where(name: 'edinburghhandedness').first
      # redcap_variable.redcap_variable_maps.build(concept_id: 0)
      # redcap_variable.save!
      #
      # other_redcap_variable = redcap_variables.where(name: 'formdate_a1_temp').first
      # omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      # redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      # redcap_variable.save!
      #
      # other_redcap_variable = redcap_variables.where(name: 'netid_1').first
      # omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      # redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      # redcap_variable.save!
    end

    def map_sa
      #REDCap Project: Data Migration Sandbox - SA
      # redcap_project          = Redcap2omop::RedcapProject.where(name: 'Data Migration Sandbox - SA').first
      redcap_project          = Redcap2omop::RedcapProject.where(project_id: 5844).first
      redcap_data_dictionary  = Redcap2omop::RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
      redcap_variables        = redcap_data_dictionary.redcap_variables

      # patient
      redcap_variable = redcap_variables.where(name: 'global_id').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'person_source_value'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable = redcap_variables.where(name: 'sex_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'gender_concept_id'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Female').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'F').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Male').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'M').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prefer not to answer').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable = redcap_variables.where(name: 'dob_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'birth_datetime'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable = redcap_variables.where(name: 'race_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'race_concept_id'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'White').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '5').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Black or African American').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '3').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'American Indian or Alaska Native').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '1').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Native Hawaiian or Other Pacific Islander').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '4').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Asian').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '2').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other (specify)').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prefer not to answer').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable = redcap_variables.where(name: 'ethnicity_stub').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'ethnicity_concept_id'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not Hispanic').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Hispanic').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prefer not to answer').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      #provider
      redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column       = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_source_value'").first
      other_omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_name'").first
      redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: redcap_variable, omop_column: other_omop_column)
      redcap_variable.save!

      #primlang
      redcap_variable = redcap_variables.where(name: 'primlang').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'Language_SpokenWrittenLanguage', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 English").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_EnglishUnitedStates', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Spanish").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_SpanishSpain', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Mandarin").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Cantonese").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Russian").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_RussianRussia', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Japanese").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_Japanese').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '8 Other primary language (specify)').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA46-8').first.concept_id)
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "9 Unknown").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #primlangx
      redcap_variable = redcap_variables.where(name: 'primlanx').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: 'Language_SpokenWrittenLanguage', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #educ
      redcap_variable = redcap_variables.where(name: 'educ').first
      redcap_variable.field_type_curated = 'integer'
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '82590-1', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '99 = Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #highestdegree_patient
      redcap_variable = redcap_variables.where(name: 'highestdegree_patient').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '82589-3', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #mc_subject_occupation
      redcap_variable = redcap_variables.where(name: 'mc_subject_occupation').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '14679004', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #maristat
      redcap_variable = redcap_variables.where(name: 'maristat').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '45404-1', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Married").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA48-4', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Widowed").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA49-2', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Divorced").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA51-8', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Separated").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4288-2', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Never married (or marriage was annulled)").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA47-6', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Living as married/domestic partner").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA15605-1').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #handed
      redcap_variable = redcap_variables.where(name: 'handed').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '57427004', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Left-handed").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '87683000', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Right-handed").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '46669005', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Ambidextrous").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '46669005', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #residenc
      redcap_variable = redcap_variables.where(name: 'residenc').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '334381000000106', standard_concept: 'S').first.concept_id) #Residence and accommodation circumstances
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Single - or multi-family private residence (apartment, condo, house)").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA10062-0', standard_concept: 'S').first.concept_id) # Private residence
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Retirement community or independent group living").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Assisted living, adult family home, or boarding home").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Skilled nursing facility, nursing home, hospital, or hospice").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      #livsitua
      redcap_variable = redcap_variables.where(name: 'livsitua').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '365481000', standard_concept: 'S').first.concept_id) # does not fully match
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Lives alone").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '105529008', standard_concept: 'S').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Lives with one other person: a spouse or partner").first
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '408821002', standard_concept: 'S').first.concept_id) # lives with partner
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '447051007', standard_concept: 'S').first.concept_id) # lives with spouse
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Lives with one other person: a relative, friend, or roommate").first
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '430793000', standard_concept: 'S').first.concept_id) # lives with roommate
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'LOINC', concept_code: 'LP97141-3').first.concept_id) # Patient lives with other person
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Lives with caregiver who is not spouse/partner, relative, or friend").first
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '224498006', standard_concept: 'S').first.concept_id) # lives with caregiver
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Lives with a group (related or not related) in a private residence").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Lives in group home (e.g., assisted living, nursing home, convent)").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      # mc_subject_driving
      redcap_variable = redcap_variables.where(name: 'mc_subject_driving').first
      redcap_variable.redcap_variable_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '129060000', standard_concept: 'S').first.concept_id)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "0 No").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA32-8').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Yes").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA33-6').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "8 Never drove").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA15728-1').first.concept_id)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      # mc_stop_driving
      redcap_variable = redcap_variables.where(name: 'mc_stop_driving').first
      redcap_variable.field_type_curated = 'integer'
      redcap_variable.redcap_variable_maps.build(concept_id: 0)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '999 = Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      # mc_car_accident
      redcap_variable = redcap_variables.where(name: 'mc_car_accident').first
      redcap_variable.redcap_variable_maps.build(concept_id: 0)
      redcap_variable.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "0 No").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA32-8').first.concept_id) # Patient lives with other person
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Yes").first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA33-6').first.concept_id) # Patient lives with other person
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
      redcap_variable_choice.save!

      redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
      redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      # mc_number_accidents
      redcap_variable = redcap_variables.where(name: 'mc_number_accidents').first
      redcap_variable.field_type_curated = 'integer'
      redcap_variable.redcap_variable_maps.build(concept_id: 0)
      redcap_variable.save!

      # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '999 = Unknown').first
      # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4489-6').first.concept_id)
      # redcap_variable_choice.save!

      other_redcap_variable = redcap_variables.where(name: 'date_visit').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!

      other_redcap_variable = redcap_variables.where(name: 'netid').first
      omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
      redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
      redcap_variable.save!
    end
  end
end
