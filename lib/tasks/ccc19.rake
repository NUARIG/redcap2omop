namespace :redcap2omop do
  namespace :setup do
    namespace :ccc19 do
      desc 'setup CCC19 project'
      task project: :environment do  |t, args|
        redcap_project = Redcap2omop::RedcapProject.where(project_id: 0 , name: 'CCC19', api_import: false).first_or_create
        file_name = 'CCC19_DataDictionary.csv'
        # file_location = "#{Rails.root}/lib/setup/data/data_dictionaries/"
        file_location = "#{Redcap2omop::Engine.root}/lib/setup/data/data_dictionaries/"
        data_dictionary = File.read("#{file_location}#{file_name}")
        data_dictionary[0]=''
        File.write("#{file_location}CCC19_DataDictionary_clean.csv", data_dictionary)
      end

      desc "setup mappings for CCC19"
      task maps: :environment do  |t, args|
        redcap_project          = Redcap2omop::RedcapProject.where(name: 'CCC19').first
        redcap_data_dictionary  = Redcap2omop::RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))

        Redcap2omop::RedcapVariableMap.joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
        Redcap2omop::RedcapVariableChoiceMap.joins(redcap_variable_choice: :redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
        Redcap2omop::RedcapVariableChildMap.joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
        Redcap2omop::RedcapDerivedDate.joins(:base_date_redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'record_id', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'person_source_value'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        #redcap_derived_date
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

        # name: 'COVID-19 Diagnosis'
        redcap_derived_date_diagnosis_covid19 = Redcap2omop::RedcapDerivedDate.where(name: 'COVID-19 Diagnosis', base_date_redcap_variable: base_date_redcap_variable, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_diagnosis_covid19.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_diagnosis_covid19.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'inclusion_yn', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'previous_report', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'this_registry', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'registry_other', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ccc19', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ccc19_exclude', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ccc19_exclude_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ccc19_institution', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'timing_of_report', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        #NCD latest phenotype
        #https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/wiki/Latest-Phenotype
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dx_year', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hcw_screen', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hcw_exclude', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'location', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'intl_stop', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        # form "patient_demographics"
        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'local_id', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'patient_id', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # add support for derived numbers
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'age', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'peds_contact', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # add support for derived numbers
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'age_exact', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gender', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'gender_concept_id'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Female').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'F').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Male').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'M').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prefer not to say').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        # come back
        # figure out how to support tracking countries
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'country_of_patient_residen', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # figure out how to support tracking states
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'state_of_patient_residence', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # figure out how to support tracking cities
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'city', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'facility', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'more_demographics', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'race', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'race_concept_id'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'American Indian/Alaska Native').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '1').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Asian').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '2').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Native Hawaiian or Other Pacific Islander').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '4').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Black or African American').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '3').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'White').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '5').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown / Not Reported').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ethnicity', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'ethnicity_concept_id'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic or Latino').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Hispanic').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'NOT Hispanic or Latino').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown / Not Reported').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'urban_rural', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Urban (city)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '78153003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Suburban (town, suburbs)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '62709005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Rural (country)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '5794003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'insurance', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Private insurance/managed care').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '314847007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Medicare').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '433661000124107').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Medicaid').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '433641000124108').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not insured').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '424553001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other government').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        #https://github.com/OHDSI/Covid-19/wiki/Release
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hcw', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'OMOP Extension', concept_code: 'OMOP4873944').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hcw_info', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ecog_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '0: Fully active, able to continue with all pre-disease activities without restriction').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '425389002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '1: Restricted in physically strenuous activity but ambulatory and able to carry out work of a light or sedentary nature, e.g., light house work, office work').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '422512005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '2: Ambulatory and capable of all self-care but unable to carry out any work activities. Up and about more than 50% of waking hours').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '422894000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '3: Capable of only limited self-care. Confined to bed or chair more than 50% of waking hours').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '423053003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '4: Completely disabled. Cannot carry on any self-care. Totally confined to bed or chair').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '423237006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'smoking_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Current smoker').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '65568007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Former smoker, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '160618006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Former smoker, quit less than 1 year ago').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '160618006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Former smoker, quit between 1 and 5 years ago').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '160618006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Former smoker, quit between 6 and 10 years ago').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '160618006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Former smoker, quit more than 10 years ago').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '160618006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Never smoker').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '8392000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'smoking_product', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'device_exposure' AND redcap2omop_omop_columns.name = 'device_exposure_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cigarettes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '722496004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cigars').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '722497008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'e-Cigarettes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '722498003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hookah pipe').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '722495000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'smoking_product_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # bad question
        # needs NLP

        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'height', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # bad question
        # needs NLP
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'weight', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'bmi', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'LOINC', concept_code: '39156-5').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'surg_med_hx_header', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # need to setup a derived date
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'recent_surgery', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'concomitant_meds', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ACE inhibitors').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'C09A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Angiotensin receptor blockers (ARBs)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'C09C').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Anti-virals').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'HemOnc', concept_code: '44995').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Antibiotics').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'J01').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Anticoagulation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Antiplatelet agents other than aspirin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AC').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Aspirin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1191').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Azithromycin (Zithromax/Z-Pak)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '18631').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Chloroquine').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2393').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hydroxychloroquine (Plaquenil)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '5521').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ibuprofen, naproxen, or other NSAIDs').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'M01A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Immunosuppressants').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'L04A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Lopinavir/Ritonavir').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'J05AR10').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Metformin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '6809').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Oseltamivir (Tamiflu)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '260101').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Statins').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'C10AA').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Systemic corticosteroids').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'H02').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Tocilizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '612865').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Tylenol (paracetamol/acetaminophen)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '161').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Vitamin D').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '11253').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        # come back
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'steroid_specific_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # dependent variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'immuno_type', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Adalimumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '327361').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Azathioprine (Imuran)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1256').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cyclophosphamide').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '3002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cyclosporine').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '3008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Everolimus').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '141704').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Fedratinib (Inrebic)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2197490').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Mercaptopurine (6-MP)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '103').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Methotrexate').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '6851').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Mycophenolate mofetil (CellCept)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '265323').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ruxolitinib (Jakafi)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1193326').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Sirolimus').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '35302').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Tacrolimus (Prograf)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '42316').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Vedolizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1538097').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'immuno_oth_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'aspirin_dose', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # dependent variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'bl_anticoag_type', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Direct factor Xa inhibitors (e.g., apixaban [Eliquis], rivaroxaban [Xarelto])').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AF').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Direct thrombin inhibitors (e.g., argatroban, dabigatran [Pradaxa])').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AE').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Fondaparinux').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '321208').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Low-molecular weight heparin (e.g., enoxaparin [Lovenox])').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AB').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unfractionated heparin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '5224').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Vitamin K antagonists (e.g., warfarin)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AA').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'bl_anticoag_reason', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'bl_anticoag_type_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'bl_anticoag_type_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'meds_other', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # dependent variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gcsf', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes, Prophylactic G-CSF use (within 1-3 days of completion of chemo)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '68442').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes, Therapeutic G-CSF use (later than 1-3 days after chemo or during a neutropenic hospitalization)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '68442').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gcsf_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'additional_meds', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # dependent variable
        # favor more specific
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'sars_vax', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # dependent variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'sars_vax_which', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'AstraZeneca vaccine (both doses)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'CPT4', concept_code: '0022A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'AstraZeneca vaccine (one dose only)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'CPT4', concept_code: '0021A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Moderna mRNA vaccine (both doses)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'CPT4', concept_code: '0012A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Moderna mRNA vaccine (one dose only)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'CPT4', concept_code: '0011A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pfizer mRNA vaccine (both doses)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'CPT4', concept_code: '0002A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pfizer mRNA vaccine (one dose only)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'CPT4', concept_code: '0001A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'sars_vax_when', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # dependent variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'influenza_vax', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'CVX', concept_code: '141').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        # dependent variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'bcg_vax', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'CVX', concept_code: '19').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'blood_type', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'A').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '112144000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'AB').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '165743006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'B').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '112149005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'O').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '58460004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'blood_type_rh', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Rh+').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '165747007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Rh-').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '165746003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'comorbid_header', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'significant_comorbidities', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
        omop_column_3 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Alcoholism').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '7200002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Asthma').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '195967001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Atrial fibrillation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '49436004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'COPD/Emphysema').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '13645005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cardiac arrhythmia, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '698247007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cardiovascular disease, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '56265001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Chronic renal insufficiency (CRI/CKD)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '723190009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cirrhosis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '19943007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Congestive heart failure (CHF) including HFpEF and HFrEF').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '42343007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Coronary artery disease (CAD)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '53741008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Deep venous thrombosis (DVT)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '128053003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Dementia').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '52448006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Diabetes mellitus').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '73211009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Diabetes mellitus with complications').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '190388001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ESRD, on dialysis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '236435004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'End-stage renal disease (ESRD), not on dialysis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '46177005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'HIV +/- AIDS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '62479008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'History of cerebrovascular accident (CVA; stroke)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '275526006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'History of hematopoietic transplant (bone marrow or stem cell)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '234336002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_3, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'History of solid organ transplant').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '313039003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hyperlipidemia (high cholesterol)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '55822004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hypertension (high blood pressure; HTN)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '38341003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ICI pneumonitis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '427046006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Immune suppression (see definition)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '38013005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Inflammatory bowel disease (IBD)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '24526004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Liver disease, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '235856003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Metabolic syndrome').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '237602007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Morbid obesity (BMI > 40 or BMI > 35 with obesity-related health conditions)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '238136002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Obesity').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '414916001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Obstructive sleep apnea (OSA)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '78275009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Peripheral vascular disease (PVD/PAD)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '400047006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pulmonary disease, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '19829001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pulmonary embolism (PE)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '59282003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Radiation pneumonitis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '84004001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Renal disease, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '90708001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Rheumatologic/Autoimmune disease').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '85828009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Seasonal allergies').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '444316004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other organs and conditions').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hiv_cd4', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '413789001').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hiv_vl', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'unit_concept_id'").first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '395058002').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Unit', concept_code: '{copies}/mL').first.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ibd', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'please_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'o2_requirement', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes, patient requires chronic supplemental O2').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '57485005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No, patient does not require supplemental O2').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'comorbid_no', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'additional_comorbid', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'comments_form_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #form covid19_details
        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_workup_why', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_workup_why_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'workup_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'symptoms', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Abdominal discomfort (other than frank abdominal pain)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '43364001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Abdominal pain').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '21522001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Altered mental status (AMS)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '419284004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Arthralgias').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '57676002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cardiac involvement').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '301095005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Conjunctivitis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '9826008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cough').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '49727002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Diarrhea').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '62315008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Dyspnea (SOB)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '267036007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Fatigue/Malaise').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '367391008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Fever').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '386661006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Headache').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '25064002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'LFT abnormalities').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '166643006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Loss of sense of smell (anosmia)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '44169009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Loss of taste (ageusia)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '36955009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Myalgias').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '68962001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Nausea').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '422587007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None (patient was asymptomatic)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '84387000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Productive cough (with sputum)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '248595008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Rhinorrhea').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '64531003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Sore throat').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '162397003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Vomiting').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '272044004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'symptoms_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'symptoms_none_why', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '243791004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_diagnosis', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Laboratory-confirmed').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'OMOP Extension', concept_code: 'OMOP4912978').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Suspected based on CT scan findings').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '840544004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Suspected based on CXR findings').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '840544004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Suspected based on contact with confirmed case').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '840544004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Suspected based on symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '840544004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_lab_type', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'value_as_concept_id'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Antigen test (ELISA)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'LOINC', concept_code: '94558-4').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA6576-8').first.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'OMOP Extension', concept_code: 'OMOP4873969').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA6576-8').first.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'PCR').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'LOINC', concept_code: '94746-5').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA6576-8').first.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Serology (antibodies to SARS-CoV-2)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'LOINC', concept_code: '94762-2').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA6576-8').first.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_dx_imaging', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'neg_test', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'value_as_concept_id'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'LOINC', concept_code: '94558-4').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA6577-6').first.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_test_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'additional_sx', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #moomin
        #redcap_variable
        #https://forums.ohdsi.org/t/covid19-etl-help-for-converting-your-data-into-omop/10269/6
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'severity_of_covid_19_v2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Mild (no hospitalization required)").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '1300591000000101').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Moderate (hospitalization indicated)").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '1300571000000100').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Severe (ICU admission indicated)").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '1300561000000107').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cytokine_yn', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '710027002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "No").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hosp_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes - admitted directly to the ICU').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes - admitted to floor').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes - admitted to floor and then transferred to the ICU').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "No").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'code_status_admit', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'code_status_change', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'code_status_change_what', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'palliative_yn', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hosp_los', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hosp_los_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'icu_los', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'current_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ER - Follow up').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'ER').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ER - new COVID-19 diagnosis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'ER').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hospitalized (non-ICU)  - continued').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hospitalized (non-ICU) - new admit').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ICU - continued').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ICU - new admit').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - follow up').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - new COVID-19 diagnosis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "None - patient is deceased").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'days_to_death_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # name: 'Death'
        redcap_derived_date_death = Redcap2omop::RedcapDerivedDate.where(parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'days_to_death_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Type Concept', vocabulary_id: 'Death Type', concept_code: 'OMOP4822229').first.concept_id , map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'death_date'").first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_death, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable.save!

        # #redcap_variable
        # redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cause_of_death', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        # redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable.save!
        #
        # omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'cause_concept_id'").first
        #
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Both').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cause_of_death', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'cause_concept_id'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Both').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'COVID-19').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cancer').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '55342001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'deceased_reason', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_systemic', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bleeding').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '43364001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Disseminated intravascular coagulation (DIC)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '67406007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Multiorgan failure').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '57653000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Sepsis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '91302008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_bleeding', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'CNS hemorrhage, extensive').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '230690007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'CNS hemorrhage, limited').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '230690007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Major bleeding (requiring multiple RBCs transfusions or ICU admit)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '230690007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Minor bleed (without transfusion need)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '230690007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Non-major but clinically relevant bleed').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '230690007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_bleeding_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dic_certainty', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Definite').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '67406007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Suspected').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dic_treatment', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'device_exposure' AND redcap2omop_omop_columns.name = 'device_exposure_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cryoprecipitate').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '256401009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Plasma (FFP)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '346447007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dic_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_comp_systemic_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'o2_requirement_c19', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '57485005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'o2_policy', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_pulm', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Acute respiratory distress syndrome (ARDS)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '67782005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Empyema').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '312682007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pleural effusion').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '60046008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pneumonia').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '233604007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pneumonitis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '205237003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pulmonary embolism (PE)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '59282003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Respiratory failure').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '409622000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'resp_failure_tx', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'device_exposure' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'BiPAP').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '425826004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'CPAP').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '467645007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'High-flow nasal cannula or blow-by').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '426854004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Intubation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '447996002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Nasal cannula or face mask with standard O2').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '336623009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Non-rebreather').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '427591007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'withdrawal_yn', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'withdrawal_who', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'berlin_yn', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'berlin_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_card', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Atrial fibrillation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '49436004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cardiomyopathy').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '85898001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cerebrovascular accident (CVA; stroke)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '230690007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Congestive heart failure (CHF)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '42343007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Deep venous thrombosis (DVT)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '128053003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hypotension').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '45007003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Myocardial infarction').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '22298006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other cardiac arrhythmia').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '698247007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other cardiac ischemia').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '414545008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pulmonary embolism (PE)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '59282003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Superficial venous thrombosis (SVT)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '275517008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Thrombosis, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '414086009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ventricular fibrillation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '71908006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'sepsis_pressors', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '870386000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_comp_card_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_gi', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Acute hepatic injury').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '427044009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ascites').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '389026000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bowel obstruction').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '81060008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bowel perforation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '56905009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ileus').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '710572000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Peritonitis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '48661000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_other', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Acute kidney injury').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '14669001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gangrene').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '372070002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Seizures').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '91175000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Thrombosis, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '414086009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        # redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'days_to_death', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # name: 'Death 2'
        redcap_derived_date_death = Redcap2omop::RedcapDerivedDate.where(parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'days_to_death', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Type Concept', vocabulary_id: 'Death Type', concept_code: 'OMOP4822229').first.concept_id , map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'death_date'").first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_death, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable.save!

        #redcap_variable
        # come back
        # condition status/discharge status/end date
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'current_status_v2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # condition status/discharge status/end date
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'current_status_retro', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        # #redcap_variable
        # redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cause_of_death_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        # redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable.save!
        #
        # omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'cause_concept_id'").first
        #
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Both').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cause_of_death_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'cause_concept_id'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Both').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'COVID-19').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cancer').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '55342001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'current_status_clinical', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first
        redcap_variable_date = Redcap2omop::RedcapVariable.where(name: 'ts_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Critical (ICU) - Severely ill, intubated').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Critical (ICU) - Severely ill, not requiring ventilator support').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Inpatient - Moderately ill').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Inpatient - Near Recovery').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Inpatient - Severely ill').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - Mild symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - Moderate symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - No symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - Severe symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Other").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'worst_status_clinical', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first
        redcap_variable_date = Redcap2omop::RedcapVariable.where(name: 'ts_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Critical (ICU) - Severely ill, intubated').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Critical (ICU) - Severely ill, did not require ventilator support').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_variable_date, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Inpatient - Moderately ill').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Inpatient - Severely ill').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - Mild symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - Moderate symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - No symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - Severe symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Other").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'complications_severity', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'complications_severity_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'worst_complications_severity', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'worst_complications_severity_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'consider_returning', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        # redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'mortality', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # name: '30 Day Survival'
        redcap_derived_date_30_day_survival = Redcap2omop::RedcapDerivedDate.where(name: '30 Day Survival', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices = {}
        redcap_variable_choices['Yes'] = 30

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_30_day_survival.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_30_day_survival.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'mortality', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_30_day_survival, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_30_day_survival, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "N/A - it has been fewer than 30 days since COVID-19 diagnosis").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "No").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'mortality_90', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # name: '90 Day Survival'
        redcap_derived_date_90_day_survival = Redcap2omop::RedcapDerivedDate.where(name: '90 Day Survival', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices = {}
        redcap_variable_choices['Yes'] = 90

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_90_day_survival.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_90_day_survival.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'mortality_90', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_90_day_survival, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_90_day_survival, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "N/A - it has been fewer than 90 days since COVID-19 diagnosis").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "No").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'mortality_180', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # name: '180 Day Survival'
        redcap_derived_date_180_day_survival = Redcap2omop::RedcapDerivedDate.where(name: '180 Day Survival', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices = {}
        redcap_variable_choices['Yes'] = 180

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_180_day_survival.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_180_day_survival.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'mortality_180', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_180_day_survival, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_180_day_survival, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "N/A - it has been fewer than 180 days since COVID-19 diagnosis").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "No").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # redcap_variable
        # come back
        # we don't have enough data to derive most of these timepoints
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'labs', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'labs_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'wbc_range', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '391558003').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "High").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '75540009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Low").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '62482003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'alc_range', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '74765001').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "High").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '75540009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Low").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '62482003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'anc_range', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '30630007').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "High").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '75540009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Low").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '62482003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hgb_range', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '271026005').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "High").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '75540009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Low").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '62482003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'plt_range', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '61928009').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "High").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '75540009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Low").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '62482003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'wbc_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '391558003').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'value_as_concept_id'").first
        redcap_variable.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Unit', vocabulary_id: 'UCUM', concept_code: '10*9/L').first.concept_id,  omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'alc', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '74765001').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'value_as_concept_id'").first
        redcap_variable.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Unit', vocabulary_id: 'UCUM', concept_code: '/uL').first.concept_id,  omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'anc', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '30630007').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'value_as_concept_id'").first
        redcap_variable.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Unit', vocabulary_id: 'UCUM', concept_code: '/uL').first.concept_id,  omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'aec', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '71960002').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'value_as_concept_id'").first
        redcap_variable.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Unit', vocabulary_id: 'UCUM', concept_code: '/uL').first.concept_id,  omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hgb', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '271026005').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'value_as_concept_id'").first
        redcap_variable.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Unit', vocabulary_id: 'UCUM', concept_code: 'g/dL').first.concept_id,  omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'plt', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '61928009').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'value_as_concept_id'").first
        redcap_variable.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Unit', vocabulary_id: 'UCUM', concept_code: '10*3/uL').first.concept_id,  omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'creat', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '70901006').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'tbili', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '359986008').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ast', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '250641004').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'alt', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '250637003').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ldh', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '250644007').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'tni', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '29964007').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hs_trop', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '121871002').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'bnp', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '390917008').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'crp', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '55235003').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'il6', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '22766004').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'pt', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '396451008').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'aptt', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '409078003').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'fibrinogen', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '250346004').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ddimer', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '103826007').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Abnormal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '263654008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'other_lab', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'creat_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '70901006').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'tbili_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '359986008').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ast_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '250641004').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'alt_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '250637003').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!


        # #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'pt_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '396451008').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'aptt_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '409078003').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'fibrinogen_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '250346004').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ddimer_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '103826007').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ldh_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '250644007').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'tni_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '29964007').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hs_trop_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '121871002').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'bnp_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '390917008').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'crp_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '55235003').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'il6_numeric', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '22766004').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'other_lab_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'coinfection_yn', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'coinfection', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Aspergillus culture-confirmed').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '2429008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Aspergillus suspected (galactomannan positive)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '709601002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bacterial infection, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '409822003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Fungal, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '414561005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gram-negative bacteria, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '81325006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gram-positive bacteria, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '8745002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Influenza A').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '407479009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Influenza B').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '407480007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ordinary coronavirus, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '84101006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pneumococcal pneumonia').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '233607000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'RSV').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '6415009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Rhinovirus').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '1838001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Viral, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '49872002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Tests are pending').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'coinfection_other', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_treatment', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first
        omop_column_3 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrecne' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Anticoagulation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Antiplatelet agents other than aspirin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AC').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Antivirals').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'HemOnc', concept_code: '44995').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Aspirin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'N02BA').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Atazanavir').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'J05AE08').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Azithromycin (Zithromax/Z-Pak)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '18631').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!


        #come back
        #reload vocabulary
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bamlanivimab').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2463114').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        #come back
        #reload vocabulary
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Casirivimab/Imdevimab').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2465242').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Chloroquine').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2393').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Continuous renal replacement therapy (CRRT)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '714749008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_3, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Extracorporeal membrane oxygenation (ECMO)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '233573008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_3, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hydroxychloroquine (Plaquenil)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '5521').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'JAK inhibitors (will prompt for additional details)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'HemOnc', concept_code: '45861').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Lopinavir/Ritonavir').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'J05AR10').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Oseltamivir (Tamiflu)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '260101').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other interleukin inhibitors (will prompt for additional details)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'L04AC').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Plasma from recovered individuals (convalescent plasma)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B05AX03').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Remdesivir').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2284718').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Statins').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'C10AA').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Systemic corticosteroids (will prompt for additional details)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'HemOnc', concept_code: '45523').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'TNF alpha inhibitors (will prompt for additional details)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'L04AB').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Tocilizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '612865').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'DEPRECATED').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_aspirin_dose', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'steroid_type', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Dexamethasone (Decadron)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '3264').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hydrocortisone (Cortef)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '5492').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Methylprednisolone (Solumedrol)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '6902').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prednisolone').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '8638').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prednisone').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '8640').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        # come back
        # more complexe than we can handle
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'steroid_specific', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'steroid_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'steroid_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_tx_interleukin', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Sarilumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'L04AC14').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'jak', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ruxolitinib (Jakafi)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'L01XE18').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Upadacitinib').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'L04AA44').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_anticoag_reason', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_tx_tnf', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Etanercept').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'L04AB01').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_anticoag_reason_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_anticoag_type', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Direct factor Xa inhibitors (e.g., apixaban [Eliquis], rivaroxaban [Xarelto])').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AF').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Direct thrombin inhibitors (e.g., argatroban, dabigatran [Pradaxa])').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AE').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Fondaparinux').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '321208').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Low-molecular weight heparin (e.g., enoxaparin [Lovenox])').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AB').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unfractionated heparin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AB01').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Vitamin K antagonists (e.g., warfarin)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AA').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_anticoag_type_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_trial_tx', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Anti-virals').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'HemOnc', concept_code: '44995').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Azithromycin (Zithromax/Z-Pak)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '18631').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        #reload vocabulary
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bamlanivimab').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2463114').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Canakinumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '853491').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        #reload vocabulary
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Casirivimab/Imdevimab').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2465242').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Guselkumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1928588').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hydroxychloroquine (Plaquenil)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '5521').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Infliximab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '191831').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Lopinavir/Ritonavir').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'J05AR10').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Plasma from recovered individuals (convalescent plasma)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B05AX03').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Remdesivir').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2284718').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Sarilumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1923319').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Systemic corticosteroids').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'HemOnc', concept_code: '45523').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Tocilizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '612865').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_trial_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'additional_tx', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'prbc', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'device_exposure' AND redcap2omop_omop_columns.name = 'device_exposure_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '431069006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'comments_form_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #form cancer_details
        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_3', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_timing', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        offset_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        offset_redcap_variable.save!

        #Assume 30 days per month
        #Assume 365 days per year
        redcap_variable_choices = {}
        redcap_variable_choices['AFTER the COVID-19 diagnosis'] = -30
        redcap_variable_choices['At the same time as COVID-19'] = 0
        redcap_variable_choices['More than 5 years ago'] = 1825
        # come back
        # redcap_variable_choices['Unknown'] = nil
        redcap_variable_choices['Within the past 5 years'] = 913
        redcap_variable_choices['Within the past year'] = 183

        # name: 'Cancer Diagnosis'
        redcap_derived_date_diagnosis_cancer = Redcap2omop::RedcapDerivedDate.where(name: 'Cancer Diagnosis', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_diagnosis_cancer.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_diagnosis_cancer.save!

        #redcap_variable
        redcap_variables = []
        redcap_variables << Redcap2omop::RedcapVariable.where(name: 'cancer_type', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variables << Redcap2omop::RedcapVariable.where(name: 'cancer_type_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variables << Redcap2omop::RedcapVariable.where(name: 'cancer_type_3', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variables << Redcap2omop::RedcapVariable.where(name: 'cancer_type_4', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variables << Redcap2omop::RedcapVariable.where(name: 'cancer_type_5', redcap_data_dictionary_id: redcap_data_dictionary.id).first

        redcap_variables.each do |redcap_variable|
          redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          redcap_variable.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'AL amyloidosis').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '23132008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Acute Leukemia').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '91855006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Acute lymphoblastic leukemia (ALL)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '91857003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Acute myeloid leukemia (AML)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '91861009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          if redcap_variable.name == 'cancer_type'
            #come back
            #not consistent
            redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Adrenocortical Carcinoma').first
            redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '255035007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
            redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
            redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
            redcap_variable_choice.save!
          end

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Aggressive lymphoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '118600007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Anal Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '448315008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Appendix Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '448992002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bile Duct Cancer (Cholangiocarcinoma)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '312104005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bladder Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '255108000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bone cancer, NOS').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '448710000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Brain (CNS) Cancer, NOS').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '372062007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Brain Cancer - benign (e.g., meningioma)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '92030004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Brain Cancer - high-grade glioma (e.g., GBM)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '393564001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Brain Cancer - low-grade glioma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '393564001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Breast Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '254838004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Burkitt lymphoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '118617000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cervical Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '285432005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Chronic lymphocytic leukemia (CLL)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '277473004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Chronic myeloid leukemia (CML)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '92818009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Colon Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '269533000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Colon/Rectum Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '781382000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Diffuse large B-cell lymphoma (DLBCL)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '109969005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Esophagus Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '372138000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ewing Sarcoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '307608006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Fallopian Tube Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '276870001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Follicular lymphoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '277618009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'GIST').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '420120006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gallbladder Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '372140005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Germ Cell Tumor').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '402878003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Head and Neck Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '255056009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Histiocyte disorder').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '127068004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hodgkin lymphoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '118599009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ill Defined/Cancer of Unknown Primary').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '255052006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          #come back
          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Indolent lymphoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '30440004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Invasive Cutaneous BCC (do not record localized BCC)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '254701007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Invasive Cutaneous SCC (do not record localized SCC)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '254651007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Liver Cancer (HCC)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '109841003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Lung Cancer, NOS').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '448993007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Lymphoproliferative disorder').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '277466009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Malignant Hematologic Neoplasm, NOS').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '129154003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Malignant Solid Neoplasm, NOS').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '369757002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Mantle cell lymphoma (MCL)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '274905008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Marginal zone lymphoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '447100004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Melanoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '372244006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Merkel Cell').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '254729005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Mesothelioma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '109378008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Multiple myeloma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '109989006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Myelodysplastic syndrome (MDS)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '109995007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Myeloproliferative neoplasm (MPN)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '109993000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Nasopharyngeal Carcinoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '449248000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Neuroblastoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '432328008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Neuroendocrine tumor (NET) or  Carcinoid').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '255046005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Non Small Cell Lung Cancer (NSCLC)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '254637007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Non-Hodgkin lymphoma (NHL)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '118601006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Osteosarcoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '735680008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ovarian Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '363443007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pancreatic Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '372142002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Parathyroid Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '255037004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Penis Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '363516004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Peritoneum Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '363492001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Placenta Cancer (incl. Choriocarcinoma)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '417570003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Plasma cell dyscrasia').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '415111003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prostate Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '254900004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Rectum and Rectosigmoid Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '93984006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Renal Kidney Cancer (RCC)').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '702391001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Renal Pelvis Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '93985007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Retinoblastoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '370967009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Rhabdomyosarcoma').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '302847003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Scrotum Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '126905005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Small Cell Lung Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '254633006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Small Intestine Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '448664009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Soft Tissue Sarcoma, NOS').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '449293008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Stomach (Gastric) Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '372143007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'T-cell and NK-cell neoplasm').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '422172005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Testis Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '713646001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Thymus Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '444231005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Thyroid Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '448216007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Uterus (Endometrial) Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '254878006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Vagina Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '254893005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Vascular Sarcoma, NOS').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '93714009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Vulva Cancer').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '447882007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Wilms Tumor').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '302849000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other Solid Tumor').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '369757002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other Heme').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '129154003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          if redcap_variable.name == 'cancer_type' || redcap_variable.name == 'cancer_type_2'
            redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
            redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '399981008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
            redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
            redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
            redcap_variable_choice.save!
          end
        end

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_type_oth', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_type_oth_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_type_oth_3', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_type_oth_4', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_type_oth_5', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'acute_leukemia_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'lung_nos_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'teravolt', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'multiple_ca', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'multiple_ca_quant', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'multiple_ca_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'breast_biomarkers', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'value_as_concept_id'").first
        omop_column_3 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        # come back
        # hardcoing to ER positive because of silly 'OR'
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Estrogen and/or progesterone-receptor positive (ER or PR positive)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '23307004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '10828004').first.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'HER2 overexpressing (HER2 positive)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '784175006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '10828004').first.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        # probably should not be a Condition
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Triple-negative breast cancer (ER, PR, and HER2 negative)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '706970001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_3, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'bcg_intraves_ever', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '214555').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gleason', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'observation_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gleason score 2').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP5000329').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gleason score 3').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4999224').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gleason score 4').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP5000253').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gleason score 5').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4997847').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gleason score 6').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4999573').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gleason score 7').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP5000187').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gleason score 8').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4998543').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gleason score 9').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4998481').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        # missing from new Cancer Modifier vocabulary
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Gleason score 10').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No needle core biopsy/TURP/prostatectomy performed').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not applicable: Information not collected for this case').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gleason_source', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # maybe use Episode
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hospice', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first
        redcap_variable_date = Redcap2omop::RedcapVariable.where(name: 'ts_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'CMS Place of Service', concept_code: '34').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "No").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'recent_treatment', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'recent_treatment', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        offset_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        offset_redcap_variable.save!

        #Assume 30 days per month
        #Assume 365 days per year
        redcap_variable_choices = {}
        redcap_variable_choices['Less than 2 weeks prior to COVID-19 diagnosis'] = 14
        redcap_variable_choices['More than 3 months prior to COVID-19 diagnosis'] = 90
        redcap_variable_choices['More than 3 months prior to COVID-19 diagnosis'] = -14
        # come back
        # redcap_variable_choices['Unknown'] = nil
        redcap_variable_choices['Within 2 to 4 weeks prior to COVID-19 diagnosis'] = 21
        redcap_variable_choices['Within the month to 3 months prior to COVID-19 diagnosis'] = 60

        # name: 'Cancer Treatment'
        redcap_derived_date_treatment_cancer = Redcap2omop::RedcapDerivedDate.where(name: 'Cancer Treatment', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_diagnosis_cancer.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_diagnosis_cancer.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hx_treatment', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'treatment_modality', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cytotoxic chemotherapy').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '367336001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Endocrine (Hormone) therapy').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '169413002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Immunotherapy').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '76334006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Intravesicular therapy (e.g., BCG)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '42284007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Radiotherapy').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '33195004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Surgery').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '387713003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        # this is not the right kind of semantic type
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Targeted therapy').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Regimen', vocabulary_id: 'HemOnc', concept_code: '18701').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        # come back
        # this is not the right kind of semantic type
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Transplant/Cellular therapy').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '77465005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'intravesicular_bcg', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Regimen', vocabulary_id: 'HemOnc', concept_code: '5106').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'tx_modality_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'what_immunotherapy', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        # come back
        # this is why we need a cancer treatment ontology
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Anti-CTLA4 antibody').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Regimen', vocabulary_id: 'HemOnc', concept_code: '?').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        # come back
        # this is why we need a cancer treatment ontology
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Anti-PD-1 antibody (e.g., nivolumab, pembrolizumab)').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Regimen', vocabulary_id: 'HemOnc', concept_code: '?').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        # come back
        # this is why we need a cancer treatment ontology
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Combination of anti-CTLA4 and anti-PD-1 (e.g. ipilimumab & nivolumab)').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Regimen', vocabulary_id: 'HemOnc', concept_code: '?').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'immuno_other_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'what_targeted_tx', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Acalabrutinib (Calquence)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1986808').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Dasatinib (Sprycel)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '475342').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Fedratinib (Inrebic)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2197490').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ibrutinib (Imbruvica)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1442981').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Imatinib (Gleevec)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '282388').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Nilotinib (Tasigna)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '662281').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ruxolitinib (Jakafi)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1193326').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'targeted_other_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'pneumonitis', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Definite irAE pneumonitis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '205237003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Likely').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '205237003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'other_irae', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'irae_text', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # if we come up with a cancer treatment modifier vocabulary
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'radiotherapy', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back

        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'transplant_prior_tx', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # this is all probably wrong
        # should go in Hemonc.org oncology treatment ontology
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'transplant_cellular_therapy', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Allogeneic SCT (donor/type unknown)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '50223000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Autologous stem cell transplant').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '709115004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'CAR-T cells').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'CPT4', concept_code: '0539T').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cord blood allogeneic SCT').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'HCPCS', concept_code: 'S2142').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Haplo allogeneic SCT').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '50223000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'MRD allogeneic SCT').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '50223000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'MUD allogeneic SCT').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '50223000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'sct_other_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'transplant_cellular_timing', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        offset_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        offset_redcap_variable.save!

        #Assume 30 days per month
        #Assume 365 days per year
        redcap_variable_choices = {}
        redcap_variable_choices['0-20 days'] = 10
        redcap_variable_choices['101-365 days'] = 284
        redcap_variable_choices['21-100 days'] = 71
        redcap_variable_choices['During prep (prior to transplant)'] = 0
        redcap_variable_choices['More than 1 year'] = 395
        # come back
        # redcap_variable_choices['Unknown'] = nil

        # name: 'Cancer Stem Cell Treatment'
        redcap_derived_date_treatment_cancer = Redcap2omop::RedcapDerivedDate.where(parent_redcap_derived_date: redcap_derived_date_treatment_cancer, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_diagnosis_cancer.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_diagnosis_cancer.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'treatment_additional', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # this should be part of a standard treatment modifier vocabulary
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'treatment_intent', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # this should be part of a standard treatment modifier vocabulary
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'treatment_context', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # this should be part of a standard treatment modifier vocabulary
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'other_context', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'orchiectomy', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        offset_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        offset_redcap_variable.save!

        #Assume 30 days per month
        #Assume 365 days per year
        redcap_variable_choices = {}
        redcap_variable_choices['Yes'] = 180
        # come back
        # redcap_variable_choices['No'] = nil
        # come back
        # redcap_variable_choices['Unknown'] = nil

        # name: 'Orchiectomy Treatment'
        redcap_derived_date_treatment_orchiectomy_cancer = Redcap2omop::RedcapDerivedDate.where(parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_diagnosis_cancer.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_diagnosis_cancer.save!

        #redcap_variable
        # come back
        # this is all probably wrong
        # should go in Hemonc.org oncology treatment ontology
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'orchiectomy', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '120001005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_orchiectomy_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'adt', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        offset_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        offset_redcap_variable.save!

        #Assume 30 days per month
        #Assume 365 days per year
        redcap_variable_choices = {}
        redcap_variable_choices['Yes'] = 180
        # come back
        # redcap_variable_choices['No'] = nil
        # come back
        # redcap_variable_choices['Unknown'] = nil

        # name: 'ADT Treatment'
        redcap_derived_date_treatment_adt_cancer = Redcap2omop::RedcapDerivedDate.where(parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_diagnosis_cancer.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_diagnosis_cancer.save!

        #redcap_variable
        # come back
        # this is all probably wrong
        # should go in Hemonc.org oncology treatment ontology
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'adt', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '707266006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_orchiectomy_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'prostate_tx', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first
        omop_column_3 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Abiraterone (Zytiga)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1100072').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Apalutamide (Erleada)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1999574').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bicalutamide (Casodex)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '83008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cabazitaxel (Jevtana)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '996051').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Carboplatin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '40048').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Darolutamide (Nubeqa)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2180325').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Docetaxel (Taxotere)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '72962').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Enzalutamide (Xtandi)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1307298').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Flutamide').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '4508').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Nilutamide').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '31805').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Olaparib').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1597582').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pembrolizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1547545').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pembrolizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1547545').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Radium-223').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '700357007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_3, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Clinical trial').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None of the above').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        # this is where a high-level treatment concept would be helpful
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other agent').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'prostate_trial_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'prostate_tx_oth', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'stage', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'observation_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '0 (in situ)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4999300').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Disseminated').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4997741').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'I').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4999639').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'II').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4999645').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'III').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4999913').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'IV').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4999934').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        #can't map
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Localized').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'stage_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'mets_yn', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'observation_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4998856').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not applicable (e.g., patient has a liquid hematologic malignancy)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'mets_sites', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'observation_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bone').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4998978').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Brain').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4998538').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Distant lymph nodes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4998666').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Generalized metastases such as carcinomatosis, malignant pleural effusion, malignant ascites').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4998856').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Liver').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP5000224').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Lung').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4999962').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other sites').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'Cancer Modifier', concept_code: 'OMOP4998856').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'mets_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'clinical_trial', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '110465008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'clinical_trial_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'additional_ca_dx', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # no timing information at all
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'prior_tx', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'drugs_expanded', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'irae_gr3', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Arthralgia').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '112144000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Arthritis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '3723001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Colitis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '64226004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Diarrhea').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '267060006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Enteritis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '64613007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hepatitis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '128241005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hypothyroidism').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '40930008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pneumonitis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '205237003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pruritis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '418290006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Rash').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '271807003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'irae_oth_specify', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        #come back
        # does this not duplicate irae_gr3
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'irae_past', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'irae_past_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'prior_tx_other', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'prior_tx_text', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'comments_form_3', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_4', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'role', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'practice_setting', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'role_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'other_role', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'email_1', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'comments_form_4', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_5', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        # redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'fu_weeks', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # name: 'Followup 1'
        redcap_derived_date_followup_1 = Redcap2omop::RedcapDerivedDate.where(name: 'Followup 1', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices = {}
        # come back
        # redcap_variable_choices['All other time intervals'] = nil
        redcap_variable_choices['Approximately 180 days after COVID-19 diagnosis'] = 180
        redcap_variable_choices['Approximately 30 days after COVID-19 diagnosis'] = 30

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_followup_1.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_followup_1.save!

        # redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'd30_vital_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # name: '30 Day Vital Status'
        redcap_derived_date_30_day_vital_status = Redcap2omop::RedcapDerivedDate.where(name: '30 Day Vital Status', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices = {}
        redcap_variable_choices['Patient was deceased within 30 days of COVID-19 diagnosis'] = 15
        # come back
        # redcap_variable_choices['Unknown'] = nil
        redcap_variable_choices['Yes the patient was alive for at least 30 days from COVID-19 diagnosis'] = 30
        redcap_variable_choices['Yes the patient was alive for at least 30 days from COVID-19 diagnosis'] = 30

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_30_day_vital_status.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_30_day_vital_status.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'd30_vital_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first
        omop_column_3 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'death_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Patient was deceased within 30 days of COVID-19 diagnosis").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Type Concept', vocabulary_id: 'Death Type', concept_code: 'OMOP4822229').first.concept_id , map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_90_day_survival, omop_column: omop_column_3, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes the patient was alive for at least 30 days from COVID-19 diagnosis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_30_day_vital_status, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_30_day_vital_status, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'd90_vital_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # name: '90 Day Vital Status'
        redcap_derived_date_90_day_vital_status = Redcap2omop::RedcapDerivedDate.where(name: '90 Day Vital Status', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices = {}
        redcap_variable_choices['Patient was deceased within 90 days of COVID-19 diagnosis'] = 30
        #come back
        # redcap_variable_choices['Unknown'] = nil
        redcap_variable_choices['Yes the patient was alive for at least 90 days from COVID-19 diagnosis'] = 90

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_90_day_vital_status.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_90_day_vital_status.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'd90_vital_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first
        omop_column_3 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'death_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Patient was deceased within 90 days of COVID-19 diagnosis").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Type Concept', vocabulary_id: 'Death Type', concept_code: 'OMOP4822229').first.concept_id , map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_90_day_vital_status, omop_column: omop_column_3, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes the patient was alive for at least 90 days from COVID-19 diagnosis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_90_day_vital_status, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_90_day_vital_status, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'd180_vital_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # name: '180 Day Vital Status'
        redcap_derived_date_180_day_vital_status = Redcap2omop::RedcapDerivedDate.where(name: '180 Day Vital Status', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices = {}
        redcap_variable_choices['Patient was deceased within 180 days of COVID-19 diagnosis'] = 90
        # come back
        # redcap_variable_choices['Unknown'] = nil
        redcap_variable_choices['Yes the patient was alive for at least 180 days from COVID-19 diagnosis'] = 180

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_180_day_vital_status.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_180_day_vital_status.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'd180_vital_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first
        omop_column_3 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'death_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Patient was deceased within 180 days of COVID-19 diagnosis").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Type Concept', vocabulary_id: 'Death Type', concept_code: 'OMOP4822229').first.concept_id , map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_180_day_vital_status, omop_column: omop_column_3, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes the patient was alive for at least 180 days from COVID-19 diagnosis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_180_day_vital_status, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_180_day_vital_status, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'timing_of_report_weeks', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'fu_reason', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'fu_reason_oth', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        # redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'timing_of_report_weeks', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        offset_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        offset_redcap_variable.save!
        # name: 'Followup 2'
        redcap_derived_date_followup_2 = Redcap2omop::RedcapDerivedDate.where(name: 'Followup 2', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable, offset_redcap_variable_numeric_interval_days: 7).first_or_create

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_status_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Fully recovered').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ongoing infection').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Recovered with complications').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Died').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # redcap_derived_date
        offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'days_to_death_fu_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # name: 'Death 2'
        redcap_derived_date_death_2 = Redcap2omop::RedcapDerivedDate.where(parent_redcap_derived_date: redcap_derived_date_diagnosis_covid19, offset_redcap_variable: offset_redcap_variable, offset_redcap_variable_numeric_interval_days: 1).first_or_create

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'days_to_death_fu_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Type Concept', vocabulary_id: 'Death Type', concept_code: 'OMOP4822229').first.concept_id , map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'death_date'").first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_death_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cause_of_death_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'cause_concept_id'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Both').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'COVID-19').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cancer').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '55342001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'deceased_reason_fu_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # can't find a map
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'who_ordinal_scale', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'who_ordinal_oth', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'current_status_clinical_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Critical (ICU) - Severely ill, intubated').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Critical (ICU) - Severely ill, not requiring ventilator support').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Inpatient - Moderately ill').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Inpatient - Near Recovery').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Inpatient - Severely ill').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - Mild symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - Moderate symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - No symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - Severe symptoms').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Other").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'current_status_clinical_specify_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # can't find a map
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'worst_complications_severity_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # can't find a map
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'complications_severity_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'complications_severity_oth_specify_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_tx_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_tx_fu_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # maybe use Episode
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_status_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hospice_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first
        redcap_variable_date = Redcap2omop::RedcapVariable.where(name: 'ts_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'CMS Place of Service', concept_code: '34').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "No").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hospice_fu_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hosp_status_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not applicable - they were admitted to the hospital at the time of the last report and remain hospitalized').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes - admitted directly to the ICU').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes - admitted to floor and then transferred to the ICU').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes - admitted to floor for the duration of the illness').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "No").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Other").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hosp_status_fu_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'admission_reason_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # maybe derived date
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hosp_los_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # maybe derived date
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hosp_los_fu_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        # come back
        # maybe derived date
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'icu_los_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'current_status_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ER - Follow up').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'ER').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hospitalized (non-ICU)  - continued').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hospitalized (non-ICU) - new admit').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ICU - continued').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ICU - new admit').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Outpatient - follow up').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OP').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "None - patient is deceased").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_bleeding_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'CNS hemorrhage, extensive').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '230690007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'CNS hemorrhage, limited').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '230690007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Major bleeding (requiring multiple RBCs transfusions or ICU admit)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '48149007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Minor bleed (without transfusion need)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '131148009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Non-major but clinically relevant bleed').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '131148009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_bleeding_oth_specify_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dic_more_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_comp_systemic_specify_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'o2_requirement_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '57485005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_pulm_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Acute respiratory distress syndrome (ARDS)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '67782005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Empyema').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '312682007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pleural effusion').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '60046008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pneumonia').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '233604007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pneumonitis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '205237003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pulmonary embolism').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '59282003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Respiratory failure').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '409622000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'resp_failure_tx_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'device_exposure' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'BiPAP').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '425826004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'CPAP').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '467645007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'High-flow nasal cannula or blow-by').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '426854004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Intubation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '447996002').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Nasal cannula or face mask with standard O2').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '336623009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Non-rebreather').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '427591007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'berlin_yn_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'berlin_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_comp_pulm_specify_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_card_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Atrial fibrillation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '49436004').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cardiomyopathy').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '85898001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cerebrovascular accident (CVA; stroke)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '230690007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Congestive heart failure (CHF)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '42343007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Deep venous thrombosis (DVT)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '128053003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hypotension').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '45007003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Myocardial infarction').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '22298006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other cardiac arrhythmia').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '698247007').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other cardiac ischemia').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '414545008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pulmonary embolism (PE)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '59282003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Superficial venous thrombosis (SVT)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '275517008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Thrombosis, NOS').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '414086009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ventricular fibrillation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '71908006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'hotn_pressors_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Yes').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'H01BA').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'No').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_comp_card_specify_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_gi_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Acute hepatic injury').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '427044009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ascites').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '389026000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bowel obstruction').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '81060008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bowel perforation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '56905009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ileus').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '710572000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Peritonitis').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '48661000').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_complications_oth_specify_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_addl_treatment', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_addl_treatment', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'additional_tx_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_treatment_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first
        omop_column_3 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrecne' AND redcap2omop_omop_columns.name = 'procedure_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Anticoagulation').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01A').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Antiplatelet agents other than aspirin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AC').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Anti-virals').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'HemOnc', concept_code: '44995').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Aspirin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'N02BA').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Azithromycin (Zithromax/Z-Pak)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '18631').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!


        #come back
        #reload vocabulary
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bamlanivimab').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2463114').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        #come back
        #reload vocabulary
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Casirivimab/Imdevimab').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2465242').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Chloroquine').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2393').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Continuous renal replacement therapy (CRRT)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '714749008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_3, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Extracorporeal membrane oxygenation (ECMO)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '233573008').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_3, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hydroxychloroquine (Plaquenil)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '5521').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'JAK inhibitors (will prompt for additional details)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'HemOnc', concept_code: '45861').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Lopinavir/Ritonavir').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'J05AR10').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Oseltamivir (Tamiflu)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '260101').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other interleukin inhibitors (will prompt for additional details)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'L04AC').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Plasma from recovered individuals (convalescent plasma)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B05AX03').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Remdesivir').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2284718').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Statins').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'C10AA').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Systemic corticosteroids (will prompt for additional details)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'HemOnc', concept_code: '45523').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'TNF alpha inhibitors (will prompt for additional details)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'L04AB').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Tocilizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '612865').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'DEPRECATED').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'None').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'steroid_type_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Dexamethasone (Decadron)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '3264').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hydrocortisone (Cortef)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '5492').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Methylprednisolone (Solumedrol)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '6902').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prednisolone').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '8638').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prednisone').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '8640').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        # come back
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'steroid_specific_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'steroid_more_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_aspirin_dose_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_anticoag_type_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Direct factor Xa inhibitors (e.g., apixaban [Eliquis], rivaroxaban [Xarelto])').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AF').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Direct thrombin inhibitors (e.g., argatroban, dabigatran [Pradaxa])').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AE').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Fondaparinux').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '321208').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Low-molecular weight heparin (e.g., enoxaparin [Lovenox])').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AB').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unfractionated heparin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AB01').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Vitamin K antagonists (e.g., warfarin)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B01AA').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_anticoag_type_oth_specify_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_anticoag_reason_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'c19_anticoag_reason_oth_specify_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_tx_interleukin_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'anakinra').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '72435').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'basiliximab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '196102').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'briakinumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '847083').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!


        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'brodalumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1872251').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'canakinumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '853491').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'daclizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '190353').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'guselkumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1928588').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ixekizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1745099').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'rilonacept').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '763450').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'risankizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2166040').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'sarilumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1923319').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'secukinumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1599788').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'siltuximab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1535218').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        # can't find a map
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'sirukumab').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1535218').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'tildrakizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2053436').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ustekinumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '847083').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'DEPRECATED').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'jak_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Baricitinib').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2047232').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Fedratinib (Inrebic)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2197490').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Oclacitinib').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1487006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Peficitinib').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1487006').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Ruxolitinib (Jakafi)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1193326').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Tofacitinib (Xeljanz)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1357536').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Upadacitinib').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2196092').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_tx_tnf_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Adalimumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '327361').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Afelimomab').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '327361').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Certolizumab pegol').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '709271').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Etanercept').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '214555').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Golimumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '819300').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Infliximab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '191831').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Opinercept').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '191831').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_treatment_trial_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!


        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_trial_tx_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Anti-virals').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'HemOnc', concept_code: '44995').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Atazanavir').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '18631').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Azithromycin (Zithromax/Z-Pak)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '18631').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        #reload vocabulary
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bamlanivimab').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2463114').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Baricitinib').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2047232').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        #reload vocabulary
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Casirivimab/Imdevimab').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2465242').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Chloroquine').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2393').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hydroxychloroquine (Plaquenil)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '5521').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Lopinavir/Ritonavir').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '195088').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Oseltamivir (Tamiflu)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '260101').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Plasma from recovered individuals (convalescent plasma)').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'B05AX03').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED


        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Remdesivir').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2284718').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Statins').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'C10AA').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Systemic corticosteroids').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'HemOnc', concept_code: '45523').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'adalimumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '327361').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'afelimomab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '327361').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'anakinra').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '72435').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'basiliximab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '196102').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'briakinumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '196102').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'brodalumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1872251').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'canakinumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '853491').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'certolizumab pegol').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '709271').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'daclizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '190353').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'etanercept').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '214555').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'golimumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '819300').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'guselkumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1928588').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'infliximab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '191831').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ixekizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1745099').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'opinercept').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'ATC', concept_code: 'L04AB07').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'rilonacept').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '763450').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'risankizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2166040').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'sarilumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1923319').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'secukinumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1599788').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'siltuximab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1535218').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #come back
        # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'sirukumab').first
        # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '?').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        # redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'tildrakizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2053436').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'tocilizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '612865').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'ustekinumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '847083').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_followup_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Other').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_trial_more_fu', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'comments_form_5', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'manual_exclude', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'exclude_why', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'manual_exclude_more', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        redcap_variable.save!


        # #redcap_variable
        # redcap_variable = Redcap2omop::RedcapVariable.where(name: 'comorbid_header', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        # redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
        # redcap_variable.save!

        #keep going
      end
    end
  end
end
