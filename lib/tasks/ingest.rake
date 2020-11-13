#bundle exec rake ingest:data_dictionary
#bundle exec rake ingest:omop_tables
#bundle exec rake ingest:maps
namespace :ingest do
  desc "Data dictionary"
  task(data_dictionary: :environment) do |t, args|
    RedcapProject.delete_all
    RedcapDataDictionary.delete_all
    RedcapVariable.delete_all
    RedcapVariableChoice.delete_all
    redcap_project = RedcapProject.where(project_id: 1, name:'test', api_token: 'test').first_or_create
    redcap_data_dictionary = RedcapDataDictionary.where(redcap_project_id: redcap_project.id, version: 1).first_or_create

    redcap_variables_from_file = CSV.new(File.open('lib/setup/data/data_dictionary.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    redcap_variables_from_file.each do |redcap_variable_from_file|
      redcap_variable = RedcapVariable.new(redcap_data_dictionary_id: redcap_data_dictionary.id)
      redcap_variable.name = redcap_variable_from_file['Variable / Field Name']
      redcap_variable.form_name = redcap_variable_from_file['Form Name']
      redcap_variable.field_type = redcap_variable_from_file['Field Type']
      redcap_variable.text_validation_type = redcap_variable_from_file['Text Validation Type OR Show Slider Number']
      redcap_variable.field_type_normalized = redcap_variable.normalize_field_type
      redcap_variable.field_label = redcap_variable_from_file['Field Label']
      redcap_variable.choices = redcap_variable_from_file['Choices, Calculations, OR Slider Labels']
      redcap_variable.field_annotation = redcap_variable_from_file['Field Annotation']
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
  end

  desc "Maps"
  task(maps: :environment) do |t, args|
    RedcapVariableMap.delete_all
    RedcapVariableChoiceMap.delete_all
    RedcapVariableChildMap.delete_all
    redcap_variable = RedcapVariable.where(name: 'record_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'person_id'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = RedcapVariable.where(name: 'gender').first
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

    redcap_variable = RedcapVariable.where(name: 'dob').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'birth_datetime'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = RedcapVariable.where(name: 'race').first
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

    redcap_variable = RedcapVariable.where(name: 'ethnicity').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'ethnicity_concept_id'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic or Latino').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Ethnicity', concept_code: 'Hispanic').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not Hispanic or Latino').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id)
    redcap_variable_choice.save!

    redcap_variable = RedcapVariable.where(name: 'record_id').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'person' AND omop_columns.name = 'person_source_value'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = RedcapVariable.where(name: 'v_coordinator').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'provider' AND omop_columns.name = 'provider_source_value'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = RedcapVariable.where(name: 'v_coordinator').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'provider' AND omop_columns.name = 'provider_name'").first
    redcap_variable.redcap_variable_maps.build(omop_column_id: omop_column.id)
    redcap_variable.save!

    redcap_variable = RedcapVariable.where(name: 'moca').first
    redcap_variable.redcap_variable_maps.build(concept_id: Concept.where(domain_id: 'Observation', concept_code: '72172-0').first.concept_id)
    redcap_variable.save!

    other_redcap_variable = RedcapVariable.where(name: 'v_d').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)

    other_redcap_variable = RedcapVariable.where(name: 'v_coordinator').first
    omop_column = OmopColumn.joins(:omop_table).where("omop_tables.name = 'observation' AND omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column)
  end
end

# observation_map_types = {}
# observation_map_types['observation_id'] = 'primary key'
# observation_map_types['person_id'] = 'person'
# observation_map_types['observation_concept_id'] = 'domain concept'
# observation_map_types['observation_date'] = 'date redcap variable'
# observation_map_types['observation_datetime'] = 'skip'
# observation_map_types['observation_type_concept_id'] = 'hardcode'
# observation_map_types['value_as_number'] = 'numeric redcap variable'
# observation_map_types['value_as_string'] = 'skip'
# observation_map_types['value_as_concept_id'] = 'choice redcap variable'
# observation_map_types['qualifier_concept_id'] = 'skip'
# observation_map_types['unit_concept_id'] = 'hardcode'
# observation_map_types['provider_id'] = 'provider'
# observation_map_types['visit_occurrence_id'] = 'visit_occurrence'
# observation_map_types['visit_detail_id'] = 'skip'
# observation_map_types['observation_source_value'] = 'redcap variable name|choice redcap variable choice description'
# observation_map_types['observation_source_concept_id'] = 'skip'
# observation_map_types['unit_source_value'] = 'skip'
# observation_map_types['qualifier_source_value'] = 'skip'