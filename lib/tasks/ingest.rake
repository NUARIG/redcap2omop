require 'webservices/redcap_api'

# bundle exec rake data:truncate_omop_clinical_data_tables
# bundle exec rake ingest:data_dictionary
# bundle exec rake ingest:omop_tables
# bundle exec rake ingest:maps
  # bundle exec rake ingest:maps_neurofiles
# bundle exec rake ingest:data
  # bundle exec rake ingest:insert_people
# bundle exec rake ingest:redcap2omop
namespace :ingest do
  desc "Data dictionary"
  task(data_dictionary: :environment) do |t, args|
    # RedcapProject.delete_all
    # redcap_project = RedcapProject.where(project_id: 5912, name:'REDCap2SQL -- sandbox 2 - Longitudinal', api_token: '').first_or_create
    # redcap_project = RedcapProject.where(project_id: 5840, name:'Data Migration Sandbox - CorePID', api_token: '?').first_or_create
    # redcap_project = RedcapProject.where(project_id: 5843, name:'Data Migration Sandbox -- PPA', api_token: '?').first_or_create
    # redcap_project = RedcapProject.where(project_id: 5843, name: 'Data Migration Sandbox - SA', api_token: '?').first_or_create

    RedcapDataDictionary.delete_all
    RedcapEventMapDependent.delete_all
    RedcapEventMap.delete_all
    RedcapEvent.delete_all
    RedcapVariableChildMap.delete_all
    RedcapVariableChoiceMap.delete_all
    RedcapVariableChoice.delete_all
    RedcapVariable.delete_all
    RedcapVariableMap.delete_all
    RedcapVariableChoice.delete_all
    RedcapVariable.delete_all

    RedcapProject.not_deleted.all.each do |redcap_project|
      ActiveRecord::Base.transaction do
        redcap_webservice = Webservices::RedcapApi.new(api_token: redcap_project.api_token)

        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        load_redcap_events(redcap_webservice, redcap_data_dictionary)
        load_redcap_variables(redcap_webservice, redcap_data_dictionary)
      end
    end
  end

  desc "OMOP tables"
  task(omop_tables: :environment) do |t, args|
    OmopTable.delete_all
    OmopColumn.delete_all

    omop_table = OmopTable.new
    omop_table.name = Person.table_name
    omop_table.save!

    person_map_types = {}
    person_map_types['person_id'] = 'record_id'
    person_map_types['gender_concept_id'] = 'choice redcap variable'
    person_map_types['year_of_birth'] = 'date redcap variable year'
    person_map_types['month_of_birth'] = 'date redcap variable month'
    person_map_types['day_of_birth'] = 'date redcap variable month day'
    person_map_types['birth_datetime'] = 'date redcap variable month'
    person_map_types['race_concept_id'] = 'choice redcap variable'
    person_map_types['ethnicity_concept_id'] = 'choice redcap variable'
    person_map_types['location_id'] = 'skip'
    person_map_types['provider_id'] = 'skip'
    person_map_types['care_site_id'] = 'skip'
    person_map_types['person_source_value'] = 'record_id'
    person_map_types['gender_source_value'] = 'choice redcap variable choice description'
    person_map_types['gender_source_concept_id'] = 'skip'
    person_map_types['race_source_value'] = 'choice redcap variable choice description'
    person_map_types['race_source_concept_id'] = 'skip'
    person_map_types['ethnicity_source_value'] ='choice redcap variable choice description'
    person_map_types['ethnicity_source_concept_id'] ='skip'

    person = Person.new
    person.attributes.keys.each do |attribute|
      omop_column = OmopColumn.new
      omop_column.omop_table = omop_table
      omop_column.name = attribute
      omop_column.data_type = person.column_for_attribute(attribute).type
      omop_column.map_type = person_map_types[attribute]
      omop_column.save!
    end

    omop_table = OmopTable.new
    omop_table.name = Provider.table_name
    omop_table.save!
    provider_map_types = {}
    provider_map_types['provider_id'] = 'primary key'
    provider_map_types['provider_name'] = 'text redcap variable'
    provider_map_types['npi'] = 'text redcap variable'
    provider_map_types['dea'] = 'text redcap variable'
    provider_map_types['specialty_concept_id'] = 'choice redcap variable'
    provider_map_types['care_site_id'] = 'care_site'
    provider_map_types['year_of_birth'] = 'date redcap variable year'
    provider_map_types['gender_concept_id'] = 'choice redcap variable'
    provider_map_types['provider_source_value'] = 'text redcap variable'
    provider_map_types['specialty_source_value'] = 'choice redcap variable choice description'
    provider_map_types['specialty_source_concept_id'] = 'skip'
    provider_map_types['gender_source_value'] = 'choice redcap variable choice description'
    provider_map_types['gender_source_concept_id'] = 'skip'

    provider = Provider.new
    provider.attributes.keys.each do |attribute|
      omop_column = OmopColumn.new
      omop_column.omop_table = omop_table
      omop_column.name = attribute
      omop_column.data_type = provider.column_for_attribute(attribute).type
      omop_column.map_type = provider_map_types[attribute]
      omop_column.save!
    end

    #Observation
    omop_table = OmopTable.new
    omop_table.domain = Observation::DOMAIN_ID
    omop_table.name = Observation.table_name
    omop_table.save!

    observation_map_types = {}
    observation_map_types['observation_id'] = 'primary key'
    observation_map_types['person_id'] = 'person'
    observation_map_types['observation_concept_id'] = 'domain concept'
    observation_map_types['observation_date'] = 'date redcap variable'
    observation_map_types['observation_datetime'] = 'skip'
    observation_map_types['observation_type_concept_id'] = 'hardcode'
    observation_map_types['value_as_number'] = 'numeric redcap variable'
    observation_map_types['value_as_string'] = 'skip'
    observation_map_types['value_as_concept_id'] = 'choice redcap variable'
    observation_map_types['qualifier_concept_id'] = 'skip'
    observation_map_types['unit_concept_id'] = 'hardcode'
    observation_map_types['provider_id'] = 'provider'
    observation_map_types['visit_occurrence_id'] = 'visit_occurrence'
    observation_map_types['visit_detail_id'] = 'skip'
    observation_map_types['observation_source_value'] = 'redcap variable name|choice redcap variable choice description'
    observation_map_types['observation_source_concept_id'] = 'skip'
    observation_map_types['unit_source_value'] = 'skip'
    observation_map_types['qualifier_source_value'] = 'skip'

    observation = Observation.new
    observation.attributes.keys.each do |attribute|
      omop_column = OmopColumn.new
      omop_column.omop_table = omop_table
      omop_column.name = attribute
      omop_column.data_type = observation.column_for_attribute(attribute).type
      omop_column.map_type = observation_map_types[attribute]
      omop_column.save!
    end

    #Measurement
    omop_table = OmopTable.new
    omop_table.domain = Measurement::DOMAIN_ID
    omop_table.name = Measurement.table_name
    omop_table.save!

    measurement_map_types = {}
    measurement_map_types['measurement_id'] = 'primary key'
    measurement_map_types['person_id'] = 'person'
    measurement_map_types['measurement_concept_id'] = 'domain concept'
    measurement_map_types['measurement_date'] = 'date redcap variable'
    measurement_map_types['measurement_datetime'] = 'skip'
    measurement_map_types['measurement_time'] = 'skip'
    measurement_map_types['measurement_type_concept_id'] = 'hardcode'
    measurement_map_types['operator_concept_id'] = 'skip'
    measurement_map_types['value_as_number'] = 'numeric redcap variable'
    measurement_map_types['value_as_concept_id'] = 'choice redcap variable'
    measurement_map_types['unit_concept_id'] = 'skip'
    measurement_map_types['range_low'] = 'skip'
    measurement_map_types['range_high'] = 'skip'
    measurement_map_types['provider_id'] = 'provider'
    measurement_map_types['visit_occurrence_id'] = 'visit_occurrence'
    measurement_map_types['visit_detail_id'] = 'skip'
    measurement_map_types['measurement_source_value'] = 'redcap variable name|choice redcap variable choice description'
    measurement_map_types['measurement_source_concept_id'] = 'skip'
    measurement_map_types['unit_source_value'] = 'skip'
    measurement_map_types['value_source_value'] = 'skip'

    measurement = Measurement.new
    measurement.attributes.keys.each do |attribute|
      omop_column = OmopColumn.new
      omop_column.omop_table = omop_table
      omop_column.name = attribute
      omop_column.data_type = measurement.column_for_attribute(attribute).type
      omop_column.map_type = measurement_map_types[attribute]
      omop_column.save!
    end
  end

  desc "Maps neurofiless"
  task(maps_neurofiles: :environment) do |t, args|
    redcap_project          = RedcapProject.where(name: 'Data Migration Sandbox - CorePID').first
    redcap_data_dictionary  = RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
    RedcapVariableMap.joins(:redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
    RedcapVariableChoiceMap.joins(redcap_variable_choice: :redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
    RedcapVariableChildMap.joins(:redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all

    redcap_project          = RedcapProject.where(name: 'Data Migration Sandbox -- PPA').first
    redcap_data_dictionary  = RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
    RedcapVariableMap.joins(:redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
    RedcapVariableChoiceMap.joins(redcap_variable_choice: :redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
    RedcapVariableChildMap.joins(:redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all

    redcap_project          = RedcapProject.where(name: 'Data Migration Sandbox - SA').first
    redcap_data_dictionary  = RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
    RedcapVariableMap.joins(:redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
    RedcapVariableChoiceMap.joins(redcap_variable_choice: :redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
    RedcapVariableChildMap.joins(:redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all

    map_core
    map_ppa
    map_sa
  end

  desc "Maps"
  task(maps: :environment) do |t, args|
    redcap_project          = RedcapProject.where(name: 'REDCap2SQL -- sandbox 2 - Longitudinal').first
    redcap_data_dictionary  = RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))

    RedcapVariableMap.joins(:redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
    RedcapVariableChoiceMap.joins(redcap_variable_choice: :redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all
    RedcapVariableChildMap.joins(:redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id).destroy_all

    #patient
    redcap_variable = RedcapVariable.where(name: 'record_id', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'person_source_value'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = RedcapVariable.where(name: 'gender', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'gender_concept_id'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Female').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Gender', concept_code: 'F').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Cis Male').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Gender', concept_code: 'M').first.concept_id)
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

    redcap_variable = RedcapVariable.where(name: 'dob', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'birth_datetime'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = RedcapVariable.where(name: 'race', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'race_concept_id'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'American Indian or Alaska Native').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Race', concept_code: '1').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Asian').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Race', concept_code: '2').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Black or African American').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Race', concept_code: '3').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic or Latino').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Native Hawaiian or Other Pacific Islander').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Race', concept_code: '4').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'White').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Race', concept_code: '5').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Unknown').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    redcap_variable = RedcapVariable.where(name: 'ethnicity', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'ethnicity_concept_id'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic or Latino').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Ethnicity', concept_code: 'Hispanic').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not Hispanic or Latino').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id)
    redcap_variable_choice.save!

    #provider
    redcap_variable = RedcapVariable.where(name: 'v_coordinator', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'provider' AND omop_columns.name = 'provider_source_value'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = RedcapVariable.where(name: 'v_coordinator').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'provider' AND omop_columns.name = 'provider_name'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    #moca
    redcap_variable = RedcapVariable.where(name: 'moca', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '72172-0').first.concept_id)
    redcap_variable.save!

    other_redcap_variable = RedcapVariable.where(name: 'v_d').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = RedcapVariable.where(name: 'v_coordinator').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #mood
    redcap_variable = RedcapVariable.where(name: 'mood', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '66773-3').first.concept_id)
    redcap_variable.save!

    other_redcap_variable = RedcapVariable.where(name: 'v_d').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = RedcapVariable.where(name: 'v_coordinator').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #clock_position_of_wound
    redcap_variable = RedcapVariable.where(name: 'clock_position_of_wound', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Measurement', concept_code: '72297-5').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 o'clock").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', concept_code: 'LA19054-8').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "11 o'clock").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', concept_code: 'LA19057-1').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "12 o'clock").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', concept_code: 'LA19055-5').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 o'clock").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', concept_code: 'LA19053-0').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 o'clock").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', concept_code: 'LA19056-3').first.concept_id)
    redcap_variable_choice.save!

    other_redcap_variable = RedcapVariable.where(name: 'v_d', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'measurement' AND omop_columns.name = 'measurement_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = RedcapVariable.where(name: 'v_coordinator', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'measurement' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!
  end

  desc "Load REDCap records"
  task(data: :environment) do |t, args|
    RedcapProject.not_deleted.all.each do |redcap_project|
      ActiveRecord::Base.transaction do
        redcap_webservice = Webservices::RedcapApi.new(api_token: redcap_project.api_token)
        records     = redcap_webservice.records
        field_names = records.first.keys
        refresh_redcap_export_table(redcap_project.export_table_name, field_names)
        load_redcap_records(redcap_project.export_table_name, records)
      end
    end
  end

  desc "Insert people"
  task(insert_people: :environment) do |t, args|
    person = Person.new
    person.person_id = Person.next_person_id
    person.gender_concept_id = 0
    person.birth_datetime = DateTime.parse('1976-10-14')
    person.race_concept_id = 0
    person.ethnicity_concept_id = 0
    person.person_source_value = 'abc123'
    person.save!
  end

  desc "REDCap2OMOP"
  task(redcap2omop: :environment) do |t, args|
    redcap_project = RedcapProject.where(name: 'REDCap2SQL -- sandbox 2 - Longitudinal').first
    redcap_project.route_to_observation = false
    redcap_project.insert_person = true
    redcap_project.save!

    if redcap_project.insert_person
      Person.delete_all
    end
    Provider.delete_all
    Observation.delete_all
    RedcapSourceLink.delete_all

    RedcapProject.not_deleted.all.each do |redcap_project|
      puts 'Start this project:'
      puts redcap_project.name
      person_redcap2omop_map = {}
      redcap_data_dictionary = RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
      redcap_variables_by_omop_table('person', redcap_data_dictionary).each do |redcap_variable_map|
        person_redcap2omop_map[redcap_variable_map.omop_column.name] = redcap_variable_map.redcap_variable.name
      end

      provider_redcap2omop_map = {}
      redcap_variables_by_omop_table('provider', redcap_data_dictionary).each do |redcap_variable_map|
        provider_redcap2omop_map[redcap_variable_map.omop_column.name] = redcap_variable_map.redcap_variable.name
      end

      redcap_records = ActiveRecord::Base.connection.select_all("select * from #{redcap_project.export_table_name}").to_a

      redcap_records.each do |redcap_export_tmp|
        if redcap_project.insert_person
          #person
          if redcap_export_tmp[person_redcap2omop_map['birth_datetime']].present? || redcap_export_tmp[person_redcap2omop_map['year_of_birth']].present?
            puts redcap_export_tmp[person_redcap2omop_map['person_source_value']]
            person = Person.where(person_source_value: redcap_export_tmp[person_redcap2omop_map['person_source_value']]).first

            unless person.present?
              person = Person.new
              person.person_id = Person.next_person_id

              person.person_source_value = redcap_export_tmp[person_redcap2omop_map['person_source_value']]
              puts 'redcap: gender_concept_id'
              puts redcap_export_tmp[person_redcap2omop_map['gender_concept_id']]
              puts 'omop: gender_concept_id'
              redcap_variable = RedcapVariable.where(name: person_redcap2omop_map['gender_concept_id'], redcap_data_dictionary_id: redcap_data_dictionary.id).first
              if redcap_variable
                gender_concept_id = redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                if gender_concept_id.present?
                  person.gender_concept_id = redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                end
              end

              if redcap_export_tmp[person_redcap2omop_map['birth_datetime']].present?
                puts 'redcap: birth_datetime'
                puts redcap_export_tmp[person_redcap2omop_map['birth_datetime']]
                puts DateTime.parse(redcap_export_tmp[person_redcap2omop_map['birth_datetime']])
                person.birth_datetime = DateTime.parse(redcap_export_tmp[person_redcap2omop_map['birth_datetime']])
              end

              if redcap_export_tmp[person_redcap2omop_map['year_of_birth']].present?
                puts 'redcap: year_of_birth'
                puts redcap_export_tmp[person_redcap2omop_map['birth_year']]
                puts redcap_export_tmp[person_redcap2omop_map['year_of_birth']]
                person.year_of_birth = redcap_export_tmp[person_redcap2omop_map['year_of_birth']]
              end

              puts 'redcap: race_concept_id'
              puts redcap_export_tmp[person_redcap2omop_map['race_concept_id']]
              puts 'omop: race_concept_id'
              redcap_variable = RedcapVariable.where(name: person_redcap2omop_map['race_concept_id'], redcap_data_dictionary_id: redcap_data_dictionary.id).first
              if redcap_variable.present?
                puts redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                person.race_concept_id = redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
              end

              puts 'redcap: ethnicity_concept_id'
              puts redcap_export_tmp[person_redcap2omop_map['ethnicity_concept_id']]
              puts 'omop: ethnicity_concept_id'
              redcap_variable = RedcapVariable.where(name: person_redcap2omop_map['ethnicity_concept_id'], redcap_data_dictionary_id: redcap_data_dictionary.id).first
              if redcap_variable.present?
                puts redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                person.ethnicity_concept_id = redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
              end

              if person.valid?
                puts 'we are creating this person'
                puts redcap_export_tmp[person_redcap2omop_map['person_source_value']]
                person.save!
              else
                puts 'we are not creating this person'
                puts redcap_export_tmp[person_redcap2omop_map['person_source_value']]
                puts person.errors.full_messages
              end
            end
          end
        end

        #provider
        if redcap_export_tmp[provider_redcap2omop_map['provider_source_value']].present?
          puts redcap_export_tmp[provider_redcap2omop_map['provider_source_value']]
          provider = Provider.where(provider_source_value: redcap_export_tmp[provider_redcap2omop_map['provider_source_value']]).first
          unless provider.present?
            provider = Provider.new
            provider.provider_id = Provider.next_provider_id
            provider.provider_source_value = redcap_export_tmp[provider_redcap2omop_map['provider_source_value']]
            provider.provider_name = redcap_export_tmp[provider_redcap2omop_map['provider_name']]
            provider.save!
          end
        end
      end

      #domain_redcap_variable
      domain_redcap_variable_maps = redcap_variables_maps_in_omop_domains(redcap_data_dictionary)
      puts 'how many domain_redcap_variable_maps'
      puts domain_redcap_variable_maps.size
      redcap_records.each do |redcap_export_tmp|
        puts redcap_export_tmp[person_redcap2omop_map['person_source_value']].inspect
        person = Person.where(person_source_value: redcap_export_tmp[person_redcap2omop_map['person_source_value']]).first
        puts person.inspect
        if person.present?
          domain_redcap_variable_maps.each do |domain_redcap_variable_map|
              puts domain_redcap_variable_map.redcap_variable.name.inspect
              puts redcap_export_tmp.inspect
            if redcap_export_tmp[domain_redcap_variable_map.redcap_variable.name].present?
              puts 'we got you'
              puts domain_redcap_variable_map.inspect
              puts domain_redcap_variable_map.redcap_variable.name
              puts domain_redcap_variable_map.concept.inspect
              if redcap_project.route_to_observation
                case domain_redcap_variable_map.concept.domain_id
                when 'Observation', 'Measurement', 'Metadata'
                  observation = Observation.new
                  observation.observation_id = Observation.next_observation_id
                  observation.person_id = person.person_id
                  observation.observation_concept_id = domain_redcap_variable_map.concept.concept_id
                  observation.observation_type_concept_id = RedcapProject.first.type_concept.concept_id
                  observation.observation_source_value = domain_redcap_variable_map.redcap_variable.name
                  case domain_redcap_variable_map.redcap_variable.determine_field_type
                  when 'integer'
                    value_as_concept_id = domain_redcap_variable_map.redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                    if value_as_concept_id.present?
                      observation.value_as_concept_id = value_as_concept_id
                    else
                      observation.value_as_number = redcap_export_tmp[domain_redcap_variable_map.redcap_variable.name].to_i
                    end
                  when 'choice'
                    puts domain_redcap_variable_map.redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                    observation.value_as_concept_id = domain_redcap_variable_map.redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                  when 'text'
                    observation.value_as_string = redcap_export_tmp[domain_redcap_variable_map.redcap_variable.name]
                  end
                  redcap_variable = domain_redcap_variable_map.redcap_variable
                  redcap_variable.redcap_variable_child_maps.each do |redcap_variable_child_map|
                    # puts redcap_variable_child_map.redcap_variable.name
                    if redcap_export_tmp[redcap_variable_child_map.redcap_variable.name].present?
                      # puts redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]
                      value = redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]
                      if redcap_variable_child_map.omop_column.name == 'provider_id'
                        value = Provider.where(provider_source_value: redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]).first.provider_id
                      end
                      observation.write_attribute(redcap_variable_child_map.omop_column.name, value)
                    else
                      puts 'not in the same row'
                      other_redcap_export_tmps =  redcap_records.select{|record| record['redcap_event_name'] == redcap_export_tmp['redcap_event_name'] && record['redcap_repeat_instrument'].blank?}
                      if other_redcap_export_tmps.size == 1
                        other_redcap_export_tmp = other_redcap_export_tmps.first
                        if other_redcap_export_tmp[redcap_variable_child_map.redcap_variable.name].present?
                          value = other_redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]
                          if redcap_variable_child_map.omop_column.name == 'provider_id'
                            value = Provider.where(provider_source_value: other_redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]).first.provider_id
                          end

                          observation.write_attribute(redcap_variable_child_map.omop_column.name, value)
                        end
                      else
                        # puts 'missed the event row'
                        # puts other_redcap_export_tmps.size
                      end
                    end
                  end
                  puts observation.inspect
                  observation.build_redcap_source_link(redcap_source: redcap_variable)
                  observation.save!
                end
              else
                #Do not route to Observation
                case domain_redcap_variable_map.concept.domain_id
                when 'Measurement'
                  measurement = Measurement.new
                  measurement.measurement_id = Measurement.next_measurement_id
                  measurement.person_id = person.person_id
                  measurement.measurement_concept_id = domain_redcap_variable_map.concept.concept_id
                  measurement.measurement_type_concept_id = RedcapProject.first.type_concept.concept_id
                  measurement.measurement_source_value = domain_redcap_variable_map.redcap_variable.name
                  case domain_redcap_variable_map.redcap_variable.determine_field_type
                  when 'integer'
                    value_as_concept_id = domain_redcap_variable_map.redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                    if value_as_concept_id.present?
                      measurement.value_as_concept_id = value_as_concept_id
                    else
                      measurement.value_as_number = redcap_export_tmp[domain_redcap_variable_map.redcap_variable.name].to_i
                    end
                  when 'choice'
                    puts domain_redcap_variable_map.redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                    measurement.value_as_concept_id = domain_redcap_variable_map.redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                  when 'text'
                    #do nothing
                    #no measurement.value_as_string column
                  end
                  redcap_variable = domain_redcap_variable_map.redcap_variable
                  redcap_variable.redcap_variable_child_maps.each do |redcap_variable_child_map|
                    # puts redcap_variable_child_map.redcap_variable.name
                    if redcap_export_tmp[redcap_variable_child_map.redcap_variable.name].present?
                      puts 'hello you'
                      puts redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]
                      puts redcap_variable_child_map.redcap_variable.name
                      value = redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]
                      if redcap_variable_child_map.omop_column.name == 'provider_id'
                        value = Provider.where(provider_source_value: redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]).first.provider_id
                      end
                      measurement.write_attribute(redcap_variable_child_map.omop_column.name, value)
                    else
                      puts 'not in the same row'
                      other_redcap_export_tmps =  redcap_records.select{|record| record['redcap_event_name'] == redcap_export_tmp['redcap_event_name'] && record['redcap_repeat_instrument'].blank?}
                      if other_redcap_export_tmps.size == 1
                        other_redcap_export_tmp = other_redcap_export_tmps.first
                        if other_redcap_export_tmp[redcap_variable_child_map.redcap_variable.name].present?
                          value = other_redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]
                          if redcap_variable_child_map.omop_column.name == 'provider_id'
                            value = Provider.where(provider_source_value: other_redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]).first.provider_id
                          end

                          measurement.write_attribute(redcap_variable_child_map.omop_column.name, value)
                        end
                      else
                        # puts 'missed the event row'
                        # puts other_redcap_export_tmps.size
                      end
                    end
                  end
                  puts measurement.inspect
                  measurement.build_redcap_source_link(redcap_source: redcap_variable)
                  measurement.save!
                when 'Observation','Metadata'
                  observation = Observation.new
                  observation.observation_id = Observation.next_observation_id
                  observation.person_id = person.person_id
                  observation.observation_concept_id = domain_redcap_variable_map.concept.concept_id
                  observation.observation_type_concept_id = RedcapProject.first.type_concept.concept_id
                  observation.observation_source_value = domain_redcap_variable_map.redcap_variable.name
                  case domain_redcap_variable_map.redcap_variable.determine_field_type
                  when 'integer'
                    value_as_concept_id = domain_redcap_variable_map.redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                    if value_as_concept_id.present?
                      observation.value_as_concept_id = value_as_concept_id
                    else
                      observation.value_as_number = redcap_export_tmp[domain_redcap_variable_map.redcap_variable.name].to_i
                    end
                  when 'choice'
                    puts domain_redcap_variable_map.redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                    observation.value_as_concept_id = domain_redcap_variable_map.redcap_variable.map_redcap_variable_choice(redcap_export_tmp)
                  when 'text'
                    observation.value_as_string = redcap_export_tmp[domain_redcap_variable_map.redcap_variable.name]
                  end
                  redcap_variable = domain_redcap_variable_map.redcap_variable
                  redcap_variable.redcap_variable_child_maps.each do |redcap_variable_child_map|
                    # puts redcap_variable_child_map.redcap_variable.name
                    if redcap_export_tmp[redcap_variable_child_map.redcap_variable.name].present?
                      # puts redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]
                      value = redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]
                      if redcap_variable_child_map.omop_column.name == 'provider_id'
                        value = Provider.where(provider_source_value: redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]).first.provider_id
                      end
                      observation.write_attribute(redcap_variable_child_map.omop_column.name, value)
                    else
                      puts 'not in the same row'
                      other_redcap_export_tmps =  redcap_records.select{|record| record['redcap_event_name'] == redcap_export_tmp['redcap_event_name'] && record['redcap_repeat_instrument'].blank?}
                      if other_redcap_export_tmps.size == 1
                        other_redcap_export_tmp = other_redcap_export_tmps.first
                        if other_redcap_export_tmp[redcap_variable_child_map.redcap_variable.name].present?
                          value = other_redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]
                          if redcap_variable_child_map.omop_column.name == 'provider_id'
                            value = Provider.where(provider_source_value: other_redcap_export_tmp[redcap_variable_child_map.redcap_variable.name]).first.provider_id
                          end

                          observation.write_attribute(redcap_variable_child_map.omop_column.name, value)
                        end
                      else
                        # puts 'missed the event row'
                        # puts other_redcap_export_tmps.size
                      end
                    end
                  end
                  puts observation.inspect
                  observation.build_redcap_source_link(redcap_source: redcap_variable)
                  observation.save!
                end
              end
            end
          end
        end
      end
    end
  end

  def redcap_variables_by_omop_table(omop_table, redcap_data_dictionary)
    RedcapVariableMap.joins(:redcap_variable, omop_column: :omop_table).where("omop_tables.name = ?", omop_table).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id)
  end

  def redcap_variables_maps_in_omop_domains(redcap_data_dictionary)
    RedcapVariableMap.joins(:concept, :redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id)
  end

  def load_redcap_events(redcap_webservice, redcap_data_dictionary)
    return unless redcap_webservice.events
    redcap_webservice.events.each do |event|
      event[:redcap_data_dictionary] = redcap_data_dictionary
      RedcapEvent.create!(event)
    end
  end

  def load_redcap_variables(redcap_webservice, redcap_data_dictionary)
    metadata  = redcap_webservice.metadata
    metadata.each do |metadata_variable|
      redcap_variable = RedcapVariable.new(redcap_data_dictionary_id: redcap_data_dictionary.id)
      redcap_variable.name                  = metadata_variable['field_name']
      redcap_variable.form_name             = metadata_variable['form_name']
      redcap_variable.field_type            = metadata_variable['field_type']
      redcap_variable.text_validation_type  = metadata_variable['text_validation_type_or_show_slider_number']
      redcap_variable.field_type_normalized = redcap_variable.normalize_field_type
      redcap_variable.field_label           = metadata_variable['field_label']
      redcap_variable.choices               = metadata_variable['select_choices_or_calculations']
      redcap_variable.field_annotation      = metadata_variable['field_annotation']
      # redcap_variable.ordinal_position
      # redcap_variable.curated

      if redcap_variable.choices.present?
        redcap_variable.choices.split('|').each_with_index do |choice, i|
          choice_code, delimiter, choice_description = choice.partition(',')
          if choice_code.present?
            choice_code.strip!
          end

          if choice_description.present?
            choice_description.strip!
          end

          if redcap_variable.field_annotation.present?
            redcap_variable.field_annotation.strip!
          end

          redcap_variable.redcap_variable_choices.build(choice_code_raw: choice_code.try(:strip), choice_description: choice_description.try(:strip), vocabulary_id_raw: redcap_variable.field_annotation.try(:strip), ordinal_position: i, curated: false)
        end
      end
      redcap_variable.save!
    end
  end

  def refresh_redcap_export_table(export_table_name, field_names)
    sql = generate_create_redcap_export_table_sql(export_table_name, field_names)
    ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS #{export_table_name}"
    ActiveRecord::Base.connection.execute sql
  end

  def generate_create_redcap_export_table_sql(export_table_name, field_names)
    sql = "CREATE TABLE #{export_table_name}"
    sql_fields = []
    field_names.each do |field_name|
      sql_fields << "#{field_name} VARCHAR(255)"
    end
    sql << " (#{sql_fields.join(',')})"
  end

  def load_redcap_records(export_table_name, records)
    records.each do |record|
      values = record.values.map{ |v| ActiveRecord::Base.connection.quote(v)}.join(',')
      ActiveRecord::Base.connection.exec_insert(
        "INSERT INTO #{export_table_name} (#{record.keys.join(',')}) VALUES (#{values})"
      )
    end
  end

  def map_core
    #REDCap Project: Data Migration Sandbox - Core
    redcap_project          = RedcapProject.where(name: 'Data Migration Sandbox - Core').first
    redcap_data_dictionary  = RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
    redcap_variables        = redcap_data_dictionary.redcap_variables

    #patient
    redcap_variable = redcap_variables.where(name: 'global_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'person_source_value'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = redcap_variables.where(name: 'sex').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'gender_concept_id'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '2 Female').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Gender', concept_code: 'F').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '1 Male').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Gender', concept_code: 'M').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable = redcap_variables.where(name: 'birthyr').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'year_of_birth'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    # redcap_variable = redcap_variables.where(name: 'dob').first
    # omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'birth_datetime'").first
    # redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    # redcap_variable.save!

    redcap_variable = redcap_variables.where(name: 'race').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'race_concept_id'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '3 American Indian or Alaska Native').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Race', concept_code: '1').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '5 Asian').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Race', concept_code: '2').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '2 Black or African American').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Race', concept_code: '3').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '4 Native Hawaiian or other Pacific Islander').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Race', concept_code: '4').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '1 White').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Race', concept_code: '5').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '99 Unknown').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '50 Other (specify)').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    redcap_variable = redcap_variables.where(name: 'hispanic').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'ethnicity_concept_id'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '1 Yes').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Ethnicity', concept_code: 'Hispanic').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '0 No (If No, SKIP TO QUESTION 9)').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown (If Unknown, SKIP TO QUESTION 9)').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    #provider
    redcap_variable = redcap_variables.where(name: 'netid_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'provider' AND omop_columns.name = 'provider_source_value'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = redcap_variables.where(name: 'netid_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'provider' AND omop_columns.name = 'provider_name'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    #primlang
    redcap_variable = redcap_variables.where(name: 'primlang').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'Language_SpokenWrittenLanguage', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 English").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_EnglishUnitedStates', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Spanish").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_SpanishSpain', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Mandarin").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Cantonese").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Russian").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_RussianRussia', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Japanese").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_Japanese').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '8 Other primary language (specify)').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    other_redcap_variable = redcap_variables.where(name: 'formdate_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'netid_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #educ
    redcap_variable = redcap_variables.where(name: 'educ').first
    redcap_variable.field_type_curated = 'integer'
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '82590-1', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '99').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    other_redcap_variable = redcap_variables.where(name: 'formdate_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'netid_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #mc_subject_profession
    redcap_variable = redcap_variables.where(name: 'mc_subject_profession').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '14679004', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'formdate_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'netid_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #maristat
    redcap_variable = redcap_variables.where(name: 'maristat').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '45404-1', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Married").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA48-4', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Widowed").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA49-2', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Divorced").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA51-8', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Separated").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4288-2', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Never married (or marriage was annulled)").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA47-6', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Living as married/domestic partner").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', vocabulary_id: 'PPI', concept_code: 'CurrentMaritalStatus_LivingWithPartner').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    other_redcap_variable = redcap_variables.where(name: 'formdate_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'netid_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #handed
    redcap_variable = redcap_variables.where(name: 'handed').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '57427004', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Left-handed").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '87683000', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Right-handed").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '46669005', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Ambidextrous").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '46669005', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    other_redcap_variable = redcap_variables.where(name: 'formdate_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'netid_ivp_a1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!
  end

  def map_ppa
    #REDCap Project: Data Migration Sandbox -- PPA
    redcap_project          = RedcapProject.where(name: 'Data Migration Sandbox -- PPA').first
    redcap_data_dictionary  = RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
    redcap_variables        = redcap_data_dictionary.redcap_variables

    #patient
    redcap_variable = redcap_variables.where(name: 'global_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'person_source_value'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    #provider
    redcap_variable = redcap_variables.where(name: 'netid_1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'provider' AND omop_columns.name = 'provider_source_value'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = redcap_variables.where(name: 'netid_1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'provider' AND omop_columns.name = 'provider_name'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    #primlang
    redcap_variable = redcap_variables.where(name: 'primlang').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'Language_SpokenWrittenLanguage', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 English").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_EnglishUnitedStates', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Spanish").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_SpanishSpain', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Mandarin").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Cantonese").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Russian").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_RussianRussia', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Japanese").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_Japanese').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '8 Other primary language (specify)').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    other_redcap_variable = redcap_variables.where(name: 'formdate_ivp_a1_temp').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'netid_1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #highestdegree_patient
    redcap_variable = redcap_variables.where(name: 'highestdegree_patient').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '82589-3', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'formdate_ivp_a1_temp').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'netid_1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #educ
    redcap_variable = redcap_variables.where(name: 'educ').first
    redcap_variable.field_type_curated = 'integer'
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '82590-1', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '99').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    other_redcap_variable = redcap_variables.where(name: 'formdate_ivp_a1_temp').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'netid_1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #mc_subject_profession
    redcap_variable = redcap_variables.where(name: 'mc_subject_profession').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '14679004', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'formdate_ivp_a1_temp').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'netid_1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #maristat
    redcap_variable = redcap_variables.where(name: 'maristat').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '45404-1', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Married").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA48-4', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Widowed").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA49-2', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Divorced").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA51-8', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Separated").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4288-2', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Never married (or marriage was annulled)").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA47-6', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Living as married/domestic partner").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', vocabulary_id: 'PPI', concept_code: 'CurrentMaritalStatus_LivingWithPartner').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    other_redcap_variable = redcap_variables.where(name: 'formdate_ivp_a1_temp').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'netid_1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #edinburghhandedness
    redcap_variable = redcap_variables.where(name: 'edinburghhandedness').first
    redcap_variable.redcap_variable_maps.build(concept_id: 0)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'formdate_ivp_a1_temp').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'netid_1').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!
  end

  def map_sa
    #REDCap Project: Data Migration Sandbox - SA
    redcap_project          = RedcapProject.where(name: 'Data Migration Sandbox - SA').first
    redcap_data_dictionary  = RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
    redcap_variables        = redcap_data_dictionary.redcap_variables

    #patient
    redcap_variable = redcap_variables.where(name: 'global_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'person_source_value'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    #provider
    redcap_variable = redcap_variables.where(name: 'net_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'provider' AND omop_columns.name = 'provider_source_value'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = redcap_variables.where(name: 'net_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'provider' AND omop_columns.name = 'provider_name'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    #primlang
    redcap_variable = redcap_variables.where(name: 'primlang').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'Language_SpokenWrittenLanguage', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 English").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_EnglishUnitedStates', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Spanish").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_SpanishSpain', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Mandarin").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Cantonese").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_ChineseHongKong', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Russian").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_RussianRussia', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Japanese").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', concept_code: 'SpokenWrittenLanguage_Japanese').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '8 Other primary language (specify)').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    other_redcap_variable = redcap_variables.where(name: 'date_visit').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'net_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #highestdegree_patient
    redcap_variable = redcap_variables.where(name: 'highestdegree_patient').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '82589-3', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'date_visit').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'net_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #educ
    redcap_variable = redcap_variables.where(name: 'educ').first
    redcap_variable.field_type_curated = 'integer'
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '82590-1', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '99').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    other_redcap_variable = redcap_variables.where(name: 'date_visit').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'net_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #mc_subject_profession
    redcap_variable = redcap_variables.where(name: 'mc_subject_profession').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '14679004', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'date_visit').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'net_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #maristat
    redcap_variable = redcap_variables.where(name: 'maristat').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '45404-1', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Married").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA48-4', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Widowed").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA49-2', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Divorced").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA51-8', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "4 Separated").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA4288-2', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "5 Never married (or marriage was annulled)").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA47-6', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 Living as married/domestic partner").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Observation', vocabulary_id: 'PPI', concept_code: 'CurrentMaritalStatus_LivingWithPartner').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    other_redcap_variable = redcap_variables.where(name: 'date_visit').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'net_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    #handed
    redcap_variable = redcap_variables.where(name: 'handed').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '57427004', standard_concept: 'S').first.concept_id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 Left-handed").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '87683000', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "2 Right-handed").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '46669005', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 Ambidextrous").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '46669005', standard_concept: 'S').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: '9 Unknown').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0)
    redcap_variable_choice.save!

    other_redcap_variable = redcap_variables.where(name: 'date_visit').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!

    other_redcap_variable = redcap_variables.where(name: 'net_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
    redcap_variable.save!
  end
end
