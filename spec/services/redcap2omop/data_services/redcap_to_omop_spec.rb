require 'rails_helper'
require 'support/helpers/stub_requests'

RSpec.describe Redcap2omop::DataServices::RedcapToOmop do
  describe 'parsing dictionary from redcap' do
    let(:project) { FactoryBot.create(:redcap_project, api_token: Faker::Lorem.word, complete_instrument: false, route_to_observation: false, insert_person: true) }
    let(:service) { Redcap2omop::DataServices::RedcapToOmop.new(redcap_project: project) }

    before(:each) do
      stub_redcap_api_metadata_request(body: File.read('spec/support/data/test_dictionary.json'))
      stub_redcap_api_record_request(body: File.read('spec/support/data/test_records.json'))
      Redcap2omop::DictionaryServices::RedcapImport.new(redcap_project: project).run
      Redcap2omop::DataServices::RedcapImport.new(redcap_project: project).run
      [Redcap2omop::Person, Redcap2omop::Provider, Redcap2omop::Observation, Redcap2omop::Measurement].map(&:setup_omop_table)
      set_person_mappings
      set_provider_mappings
    end

    describe 'handling person records' do
      it 'inserts person records if project has a flag' do
        project.insert_person = true
        project.save!

        expect(Redcap2omop::Person.count).to eq 0
        expect{ service.run }.to change{ Redcap2omop::Person.count }.by(1)
        person = Redcap2omop::Person.last
        expect(person.year_of_birth).to eq 1976
        expect(person.month_of_birth).to eq 10
        expect(person.day_of_birth).to eq 14
        expect(person.birth_datetime).to eq '1976-10-14'
        expect(person.gender_concept_id).to eq Redcap2omop::Concept.where(domain_id: 'Gender', concept_code: 'M').first.concept_id
        expect(person.race_concept_id).to eq Redcap2omop::Concept.where(domain_id: 'Race', concept_code: '2').first.concept_id
        expect(person.ethnicity_concept_id).to eq Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id
        expect(person.person_source_value).to eq 'abc123'
      end

      it 'does not insert person record if project has no flag' do
        project.insert_person = false
        project.save!
        expect{ service.run }.not_to change{ Redcap2omop::Person.count }
      end
    end

    describe 'handling providers' do
      it 'creates provider records' do
        expect(Redcap2omop::Provider.count).to eq 0
        expect{ service.run }.to change{ Redcap2omop::Provider.count }.by(4)
        array = ['Michaela', 'Christina', 'Beth', 'Beth and Christina'].map{|p| [p,p]}
        expect(Redcap2omop::Provider.pluck(:provider_name, :provider_source_value)).to match_array(array)
      end
    end

    describe 'routing data' do
      before(:each) do
        set_mood
        set_clock_position_of_wound
        @observation_concept_id = Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '66773-3').first.concept_id
        @measurement_concept_id = Redcap2omop::Concept.where(domain_id: 'Measurement', concept_code: '72297-5').first.concept_id
      end

      it 'routes all data to observations if flag is set' do
        project.route_to_observation = true
        project.save!

        expect(Redcap2omop::Observation.count).to eq 0
        result = service.run
        expect(result.success).to eq false
        expect(result.message).to match("PG::NotNullViolation: ERROR:  null value in column \"observation_date\" violates not-null constraint")

        redcap_data_dictionary = project.redcap_data_dictionaries.last
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'clock_position_of_wound', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        redcap_variable.redcap_variable_child_maps.destroy_all

        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_d', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE )
        redcap_variable.save!

        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_coordinator', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        service.run
        expect(Redcap2omop::Observation.count).to eq 19
        expect(Redcap2omop::Observation.where(observation_concept_id: @observation_concept_id).count).to eq 10
        expect(Redcap2omop::Observation.where(observation_concept_id: @measurement_concept_id).count).to eq 9
      end

      it 'routes data to proper tables if route_to_observation flag is not set' do
        project.route_to_observation = false
        project.save!

        expect(Redcap2omop::Observation.count).to eq 0
        expect(Redcap2omop::Measurement.count).to eq 0
        service.run
        expect(Redcap2omop::Observation.count).to eq 10
        expect(Redcap2omop::Measurement.count).to eq 9

        Redcap2omop::Observation.all.each do |observation|
          expect(observation.observation_concept_id).to eq Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '66773-3').first.concept_id
        end
        Redcap2omop::Measurement.all.each do |measurement|
          expect(measurement.measurement_concept_id).to eq Redcap2omop::Concept.where(domain_id: 'Measurement', concept_code: '72297-5').first.concept_id
        end
      end
    end

    describe 'handling incomplete data' do
      before(:each) do
        set_mood
        set_clock_position_of_wound
        @observation_concept_id = Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '66773-3').first.concept_id
        @measurement_concept_id = Redcap2omop::Concept.where(domain_id: 'Measurement', concept_code: '72297-5').first.concept_id
      end

      it 'ignores incomplete instruments if complete_instrument flag is set to true' do
        project.complete_instrument = true
        project.save!

        service.run
        expect(Redcap2omop::Observation.where(observation_concept_id: @observation_concept_id).count).to eq 8
        expect(Redcap2omop::Measurement.where(measurement_concept_id: @measurement_concept_id).count).to eq 7
      end

      it 'imports incomplete instruments if complete_instrument flag is set to false' do
        project.complete_instrument = false
        project.save!

        service.run
        expect(Redcap2omop::Observation.where(observation_concept_id: @observation_concept_id).count).to eq 10
        expect(Redcap2omop::Measurement.where(measurement_concept_id: @measurement_concept_id).count).to eq 9
      end
    end

    describe 'setting mappings' do
      it 'handles integer values' do
        # this also checks inferred dates for repeat events
        set_moca
        expect(Redcap2omop::Observation.count).to eq 0
        expect{ service.run }.to change{ Redcap2omop::Observation.count }.by(11)
        data_rows = [
          {person: 'abc123', date: '2020-10-23', provider: 'Michaela', value: 87},
          {person: 'abc123', date: '2020-11-27', provider: 'Michaela', value: 67},
          {person: 'abc123', date: '2020-10-30', provider: 'Michaela', value: 50},
          {person: 'abc123', date: '2020-10-30', provider: 'Michaela', value: 54},
          {person: 'abc123', date: '2020-10-30', provider: 'Michaela', value: 12},
          {person: 'abc123', date: '2021-04-22', provider: 'Christina', value: 47},
          {person: 'abc123', date: '2021-04-22', provider: 'Christina', value: 55},
          {person: 'abc123', date: '2021-04-22', provider: 'Christina', value: 44},
          {person: 'abc123', date: '2020-10-19', provider: 'Beth', value: 77},
          {person: 'abc123', date: '2020-12-24', provider: 'Beth', value: 90},
          {person: 'abc123', date: '2021-02-08', provider: 'Beth and Christina', value: 44}
        ]
        data_rows.each do |data_row|
          observations = Redcap2omop::Observation.where(observation_date: data_row[:date], value_as_number: data_row[:value])
          expect(observations).not_to be_empty
          expect(observations.count).to eq 1
          expect(observations.first.provider.provider_name).to      eq data_row[:provider]
          expect(observations.first.person.person_source_value).to  eq data_row[:person]
        end
      end

      describe 'handling choice values' do
        it 'maps choices' do
          set_clock_position_of_wound
          expect(Redcap2omop::Measurement.count).to eq 0
          expect{ service.run }.to change{ Redcap2omop::Measurement.count }.by(9)
          data_rows = [
            {person: 'abc123', date: '2020-10-23', provider: 'Michaela', concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19055-5').first.concept_id},
            {person: 'abc123', date: '2020-11-27', provider: 'Michaela', concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19053-0').first.concept_id},
            {person: 'abc123', date: '2020-10-30', provider: 'Michaela', concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19055-5').first.concept_id},
            {person: 'abc123', date: '2021-04-22', provider: 'Christina', concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19053-0').first.concept_id},
            {person: 'abc123', date: '2021-04-22', provider: 'Christina', concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19057-1').first.concept_id},
            {person: 'abc123', date: '2021-04-22', provider: 'Christina', concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19054-8').first.concept_id},
            {person: 'abc123', date: '2020-10-19', provider: 'Beth', concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19055-5').first.concept_id},
            {person: 'abc123', date: '2020-12-24', provider: 'Beth', concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19057-1').first.concept_id},
            {person: 'abc123', date: '2021-02-08', provider: 'Beth and Christina', concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19053-0').first.concept_id}
          ]

          data_rows.each do |data_row|
            measurements = Redcap2omop::Measurement.where(measurement_date: data_row[:date], value_as_concept_id: data_row[:concept_id])
            puts measurements.to_sql
            expect(measurements).not_to be_empty
            expect(measurements.count).to eq 1
            expect(measurements.first.measurement_concept_id).to      eq Redcap2omop::Concept.where(domain_id: 'Measurement', concept_code: '72297-5').first.concept_id
            expect(measurements.first.provider.provider_name).to      eq data_row[:provider]
            expect(measurements.first.person.person_source_value).to  eq data_row[:person]
          end
        end

        xit 'maps choice to integer if specified' do
        end
      end
    end
  end

  def set_person_mappings
    redcap_data_dictionary = project.redcap_data_dictionaries.last
    redcap_variable = Redcap2omop::RedcapVariable.where(name: 'record_id', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column     = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'person_source_value'").first
    redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
    redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
    redcap_variable.save!

    redcap_variable = Redcap2omop::RedcapVariable.where(name: 'gender', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column     = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'gender_concept_id'").first
    redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
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

    redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dob', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column     = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'birth_datetime'").first
    redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
    redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
    redcap_variable.save!

    redcap_variable = Redcap2omop::RedcapVariable.where(name: 'race', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column     = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'race_concept_id'").first
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

    redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ethnicity', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'person' AND redcap2omop_omop_columns.name = 'ethnicity_concept_id'").first
    redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
    redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Hispanic or Latino').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Hispanic').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
    redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Not Hispanic or Latino').first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Ethnicity', concept_code: 'Not Hispanic').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
    redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
    redcap_variable_choice.save!
  end

  def set_provider_mappings
    redcap_data_dictionary = project.redcap_data_dictionaries.last
    redcap_variable   = Redcap2omop::RedcapVariable.where(name: 'v_coordinator', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column       = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_source_value'").first
    other_omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'provider' AND redcap2omop_omop_columns.name = 'provider_name'").first
    redcap_variable.build_redcap_variable_map(omop_column_id: omop_column.id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN)
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: redcap_variable, omop_column: other_omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
    redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
    redcap_variable.save!
  end

  def set_clock_position_of_wound
    redcap_data_dictionary = project.redcap_data_dictionaries.last
    redcap_variable = Redcap2omop::RedcapVariable.where(name: 'clock_position_of_wound', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Measurement', concept_code: '72297-5').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
    redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
    redcap_variable.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "1 o'clock").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19054-8').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
    redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "11 o'clock").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19057-1').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
    redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "12 o'clock").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19055-5').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
    redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "3 o'clock").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19053-0').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
    redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
    redcap_variable_choice.save!

    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: "6 o'clock").first
    redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Meas Value', concept_code: 'LA19056-3').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
    redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
    redcap_variable_choice.save!

    other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_d', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE )
    redcap_variable.save!

    other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_coordinator', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
    redcap_variable.save!
  end

  def set_mood
    redcap_data_dictionary = project.redcap_data_dictionaries.last
    redcap_variable = Redcap2omop::RedcapVariable.where(name: 'mood', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '66773-3').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT )
    redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
    redcap_variable.save!

    other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_d').first
    omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
    redcap_variable.save!

    other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_coordinator').first
    omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
    redcap_variable.save!
  end

  def set_moca
    redcap_data_dictionary = project.redcap_data_dictionaries.last
    redcap_variable = Redcap2omop::RedcapVariable.where(name: 'moca', redcap_data_dictionary_id: redcap_data_dictionary.id).first
    redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Observation', concept_code: '72172-0').first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT )
    redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
    redcap_variable.save!

    other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_d').first
    omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
    redcap_variable.save!

    other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_coordinator').first
    omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
    redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
    redcap_variable.save!
  end
end
