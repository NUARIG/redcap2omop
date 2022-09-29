namespace :redcap2omop do
  namespace :setup do
    namespace :demo do
      desc 'setup Demo project'
      task project: :environment do  |t, args|
        redcap_project = Redcap2omop::RedcapProject.new(project_id: 0 , name: 'Demo', api_import: true, insert_person: true, api_token: ENV["REDCAP2_OMOP_API_TOKEN"]).save!
      end

      desc "setup mappings for Demo"
      task maps: :environment do  |t, args|
        redcap_project          = Redcap2omop::RedcapProject.where(name: 'Demo').first
        redcap_data_dictionary  = Redcap2omop::RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))

        #patient
        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'record_id', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'person_source_value'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gender', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'gender_concept_id'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Female').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'F').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Male').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'M').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Trans Female').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Transe Male').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Non-binary').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dob', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'birth_datetime'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'race', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'race_concept_id'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'American Indian or Alaska Native').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '1').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Asian').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '2').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Black or African American').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '3').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic or Latino').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Native Hawaiian or Other Pacific Islander').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '4').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'White').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '5').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ethnicity', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'ethnicity_concept_id'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic or Latino').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Hispanic').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not Hispanic or Latino').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #provider
        #redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'diagnosing_provider', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column       = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_source_value'").first
        other_omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_name'").first
        redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
        redcap_variable.redcap_variable_child_maps.build(redcap_variable: redcap_variable, omop_column: other_omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        #redcap variable
        # Cancer Diagnosis Type
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_diagnosis_type', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        other_redcap_variable_1 = Redcap2omop::RedcapVariable.where(name: 'cancer_diagnosis_dt', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first
        other_redcap_variable_2 = Redcap2omop::RedcapVariable.where(name: 'diagnosing_provider', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'provider_id'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Malignant Breast Cancer').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '254837009').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Pancreatic Cancer').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '363418001').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Prostate Cancer').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '399068003').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Brain Cancer').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '428061005').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        #redcap variable
        # Drug Regimen
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'drug_regimen_component', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        other_redcap_variable_1 = Redcap2omop::RedcapVariable.where(name: 'drug_regimen_begin_dt', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first

        other_redcap_variable_2 = Redcap2omop::RedcapVariable.where(name: 'drug_regimen_end_dt', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Bevacizumab').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '253337').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Carboplatin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '40048').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cisplatin').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2555').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Etoposide').first
        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '4179').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_2, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'aec', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '71960002').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        other_redcap_variable_1 = Redcap2omop::RedcapVariable.where(name: 'aec_date', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'unit_concept_id'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Unit', vocabulary_id: 'UCUM', concept_code: '/uL').first.concept_id,  omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'aec_range', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '71960002').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        other_redcap_variable_1 = Redcap2omop::RedcapVariable.where(name: 'aec_date', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
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
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ldh', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '250644007').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        other_redcap_variable_1 = Redcap2omop::RedcapVariable.where(name: 'ldh_date', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'unit_concept_id'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.redcap_variable_child_maps.build(concept_id: Redcap2omop::Concept.where(domain_id: 'Unit', vocabulary_id: 'UCUM', concept_code: '/uL').first.concept_id,  omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        # redcap_variable
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ldh_range', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '250644007').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        other_redcap_variable_1 = Redcap2omop::RedcapVariable.where(name: 'ldh_date', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable_1, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
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

        redcap_variable.save!
      end
    end
  end
end
