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
      Redcap2omop::Setup.omop_tables
      set_person_mappings
      set_provider_mappings
    end

    describe 'legacy' do
      before(:each) do
        Redcap2omop::DataServices::RedcapImport.new(redcap_project: project).run
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
        end
      end
    end

    describe 'CCC19 Coverage' do
      describe 'can map a REDCap derived date from a parent REDCap derived date with a numeric offset REDCap variable' do
        before(:each) do
          redcap_data_dictionary = project.redcap_data_dictionaries.last
          base_date_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_0', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          base_date_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
          base_date_redcap_variable.save!

          covid_19_offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_dx_interval', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          covid_19_offset_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
          covid_19_offset_redcap_variable.save!

          @covid_19_redcap_variable_choices = {}
          @covid_19_redcap_variable_choices['Within the past week'] = 4
          @covid_19_redcap_variable_choices['Within the past 1 to 2 weeks'] = 11
          @covid_19_redcap_variable_choices['Within the past 2 to 4 weeks'] = 21
          @covid_19_redcap_variable_choices['Within the past 4 to 8 weeks'] = 42
          @covid_19_redcap_variable_choices['Within the past 8 to 12 weeks'] = 70
          @covid_19_redcap_variable_choices['Within the past 3 to 6 months'] = 135
          @covid_19_redcap_variable_choices['More than 6 months ago'] = 270
          @covid_19_redcap_variable_choices['Within the past 6 to 9 months'] = 225
          @covid_19_redcap_variable_choices['Within the past 9 to 12 months'] = 315
          @covid_19_redcap_variable_choices['More than 12 months ago'] = 450

          redcap_derived_date_diagnosis_covid_19 = Redcap2omop::RedcapDerivedDate.where(name: 'COVID-19 Diagnosis', base_date_redcap_variable: base_date_redcap_variable, offset_redcap_variable: covid_19_offset_redcap_variable).first_or_create

          @covid_19_redcap_variable_choices.each do |k,v|
            redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: covid_19_offset_redcap_variable.id, choice_description: k).first
            redcap_derived_date_diagnosis_covid_19.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
          end
          redcap_derived_date_diagnosis_covid_19.save!

          redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dx_year', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          covid_19_concept = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first
          redcap_variable.build_redcap_variable_map(concept_id: covid_19_concept.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first
          redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid_19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable.save!

          death_offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'days_to_death_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @redcap_derived_date_death = Redcap2omop::RedcapDerivedDate.where(name: 'Death', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid_19, offset_redcap_variable: death_offset_redcap_variable).first_or_create

          @days_to_death_2_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'days_to_death_2', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @death_type_concept = Redcap2omop::Concept.where(domain_id: 'Type Concept', vocabulary_id: 'Death Type', concept_code: 'OMOP4822229').first
          @days_to_death_2_redcap_variable.build_redcap_variable_map(concept_id:  @death_type_concept.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'death_date'").first
          @days_to_death_2_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @days_to_death_2_redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: @redcap_derived_date_death, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'death' AND redcap2omop_omop_columns.name = 'cause_concept_id'").first
          @redcap_variable_cause_of_death = Redcap2omop::RedcapVariable.where(name: 'cause_of_death', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @days_to_death_2_redcap_variable.redcap_variable_child_maps.build(redcap_variable: @redcap_variable_cause_of_death, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_cause_of_death_choice_1 = @redcap_variable_cause_of_death.redcap_variable_choices.where(choice_description: 'Both').first
          @cause_of_death_concept_1 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first
          @redcap_variable_cause_of_death_choice_1.build_redcap_variable_choice_map(concept_id: @cause_of_death_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_cause_of_death_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_cause_of_death_choice_1.save!

          @redcap_variable_cause_of_death_choice_2 = @redcap_variable_cause_of_death.redcap_variable_choices.where(choice_description: 'COVID-19').first
          @cause_of_death_concept_2 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first
          @redcap_variable_cause_of_death_choice_2.build_redcap_variable_choice_map(concept_id: @cause_of_death_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_cause_of_death_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_cause_of_death_choice_2.save!

          @redcap_variable_cause_of_death_choice_3 = @redcap_variable_cause_of_death.redcap_variable_choices.where(choice_description: 'Cancer').first
          @cause_of_death_concept_3 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '55342001').first
          @redcap_variable_cause_of_death_choice_3.build_redcap_variable_choice_map(concept_id: @cause_of_death_concept_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_cause_of_death_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_cause_of_death_choice_3.save!

          @redcap_variable_cause_of_death_choice_4 = @redcap_variable_cause_of_death.redcap_variable_choices.where(choice_description: 'Other').first
          @redcap_variable_cause_of_death_choice_4.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_cause_of_death_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_cause_of_death_choice_4.save!

          @redcap_variable_cause_of_death_choice_5 = @redcap_variable_cause_of_death.redcap_variable_choices.where(choice_description: 'Unknown').first
          @redcap_variable_cause_of_death_choice_5.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_cause_of_death_choice_5.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_cause_of_death_choice_5.save!
          @days_to_death_2_redcap_variable.save!

          @record_id_1 = 'abc123'
          @record_id_2 = 'abc456'
          @record_id_3 = 'abc789'
          @record_id_4 = 'def123'
          screening_d_1 = '2021-03-30'
          screening_d_2 = '2021-04-30'
          screening_d_3 = '2021-01-30'
          screening_d_4 = '2021-02-30'
          @ts_0_1 = '2021-04-07 12:46'
          @ts_0_2 = '2021-06-01 10:00'
          @ts_0_3 = '2021-01-01 10:00'
          @ts_0_4 = '2021-01-15 10:00'

          @covid_19_dx_interval_choice_description_1 = 'Within the past 1 to 2 weeks'
          covid_19_dx_interval_choice_code_raw_1 = covid_19_offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @covid_19_dx_interval_choice_description_1 }.choice_code_raw
          @covid_19_dx_interval_choice_description_2 = 'Within the past 8 to 12 weeks'
          covid_19_dx_interval_choice_code_raw_2 = covid_19_offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @covid_19_dx_interval_choice_description_2 }.choice_code_raw
          @covid_19_dx_interval_choice_description_3 = 'More than 12 months ago'
          covid_19_dx_interval_choice_code_raw_3 = covid_19_offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @covid_19_dx_interval_choice_description_3 }.choice_code_raw

          @days_to_death_2_record_id_1 = 45
          @days_to_death_2_record_id_2 = 90
          @days_to_death_2_record_id_3 = nil
  @records = <<-RECORDS
  [
    {
      "record_id": "#{@record_id_1}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "ts_0":"#{@ts_0_1}",
      "covid_19_dx_interval":"#{covid_19_dx_interval_choice_code_raw_1}",
      "dx_year": "2020",
      "days_to_death_2":"#{@days_to_death_2_record_id_1}",
      "cause_of_death":"#{@redcap_variable_cause_of_death_choice_1.choice_code_raw}",
      "screending_d": "#{screening_d_1}",
      "urban_rural": "1",
      "concomitant_meds___n02ba": "1",
      "concomitant_meds___rxcui_18631": "0",
      "concomitant_meds___rxcui_2393": "0",
      "concomitant_meds___rxcui_5521": "1",
      "concomitant_meds___oth": "0",
      "concomitant_meds___none": "0",
      "concomitant_meds___unk": "0",
      "covid_19_lab_type___94558_4":"1",
      "covid_19_lab_type___94746_5":"1",
      "covid_19_lab_type___94762_2":"0",
      "covid_19_lab_type___la14698_7":"0",
      "covid_19_lab_type___la4489_6":"0",
      "c19_complications_systemic___50960005":"0",
      "c19_complications_systemic___67406007":"1",
      "c19_complications_systemic___57653000":"0",
      "c19_complications_systemic___91302008":"1",
      "c19_complications_systemic___238147009":"0",
      "c19_complications_systemic___none":"0",
      "c19_complications_systemic___unk":"0",
      "coinfection___2429008":"1",
      "coinfection___709601002":"1",
      "coinfection___409822003":"0",
      "coinfection___414561005":"0",
      "coinfection___81325006":"0",
      "coinfection___8745002":"0",
      "coinfection___407479009":"0",
      "coinfection___407480007":"0",
      "coinfection___84101006":"0",
      "coinfection___233607000":"0",
      "coinfection___6415009":"0",
      "coinfection___1838001":"0",
      "coinfection___49872002":"0",
      "coinfection___442376007":"0",
      "coinfection___none":"0",
      "coinfection___oth":"0",
      "coinfection___unk":"0",
      "treatment_modality___685":"1",
      "treatment_modality___691":"0",
      "treatment_modality___694":"1",
      "treatment_modality___45215":"0",
      "treatment_modality___695":"0",
      "treatment_modality___14051":"0",
      "treatment_modality___58229":"0",
      "treatment_modality___45186":"0",
      "treatment_modality___oth":"0",
      "screening_form_complete": "2",
      "first_name": "Firas",
      "last_name": "Wehbe",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    },
    {
      "record_id": "#{@record_id_2}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "ts_0":"#{@ts_0_2}",
      "covid_19_dx_interval":"#{covid_19_dx_interval_choice_code_raw_2}",
      "dx_year": "2020",
      "days_to_death_2":"#{@days_to_death_2_record_id_2}",
      "cause_of_death":"#{@redcap_variable_cause_of_death_choice_1.choice_code_raw}",
      "screending_d": "#{screening_d_2}",
      "urban_rural": "1",
      "concomitant_meds___n02ba": "1",
      "concomitant_meds___rxcui_18631": "0",
      "concomitant_meds___rxcui_2393": "0",
      "concomitant_meds___rxcui_5521": "1",
      "concomitant_meds___oth": "0",
      "concomitant_meds___none": "0",
      "concomitant_meds___unk": "0",
      "covid_19_lab_type___94558_4":"1",
      "covid_19_lab_type___94746_5":"1",
      "covid_19_lab_type___94762_2":"0",
      "covid_19_lab_type___la14698_7":"0",
      "covid_19_lab_type___la4489_6":"0",
      "c19_complications_systemic___50960005":"0",
      "c19_complications_systemic___67406007":"1",
      "c19_complications_systemic___57653000":"0",
      "c19_complications_systemic___91302008":"1",
      "c19_complications_systemic___238147009":"0",
      "c19_complications_systemic___none":"0",
      "c19_complications_systemic___unk":"0",
      "coinfection___2429008":"1",
      "coinfection___709601002":"1",
      "coinfection___409822003":"0",
      "coinfection___414561005":"0",
      "coinfection___81325006":"0",
      "coinfection___8745002":"0",
      "coinfection___407479009":"0",
      "coinfection___407480007":"0",
      "coinfection___84101006":"0",
      "coinfection___233607000":"0",
      "coinfection___6415009":"0",
      "coinfection___1838001":"0",
      "coinfection___49872002":"0",
      "coinfection___442376007":"0",
      "coinfection___none":"0",
      "coinfection___oth":"0",
      "coinfection___unk":"0",
      "treatment_modality___685":"1",
      "treatment_modality___691":"0",
      "treatment_modality___694":"1",
      "treatment_modality___45215":"0",
      "treatment_modality___695":"0",
      "treatment_modality___14051":"0",
      "treatment_modality___58229":"0",
      "treatment_modality___45186":"0",
      "treatment_modality___oth":"0",
      "screening_form_complete": "2",
      "first_name": "Firas",
      "last_name": "Wehbe",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    },
    {
      "record_id": "#{@record_id_3}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "ts_0":"#{@ts_0_3}",
      "covid_19_dx_interval":"#{covid_19_dx_interval_choice_code_raw_3}",
      "dx_year": "2020",
      "days_to_death_2":"#{@days_to_death_2_record_id_1}",
      "cause_of_death":"#{@redcap_variable_cause_of_death_choice_1.choice_code_raw}",
      "screending_d": "#{screening_d_3}",
      "urban_rural": "1",
      "concomitant_meds___n02ba": "1",
      "concomitant_meds___rxcui_18631": "0",
      "concomitant_meds___rxcui_2393": "0",
      "concomitant_meds___rxcui_5521": "1",
      "concomitant_meds___oth": "0",
      "concomitant_meds___none": "0",
      "concomitant_meds___unk": "0",
      "covid_19_lab_type___94558_4":"1",
      "covid_19_lab_type___94746_5":"1",
      "covid_19_lab_type___94762_2":"0",
      "covid_19_lab_type___la14698_7":"0",
      "covid_19_lab_type___la4489_6":"0",
      "c19_complications_systemic___50960005":"0",
      "c19_complications_systemic___67406007":"1",
      "c19_complications_systemic___57653000":"0",
      "c19_complications_systemic___91302008":"1",
      "c19_complications_systemic___238147009":"0",
      "c19_complications_systemic___none":"0",
      "c19_complications_systemic___unk":"0",
      "coinfection___2429008":"1",
      "coinfection___709601002":"1",
      "coinfection___409822003":"0",
      "coinfection___414561005":"0",
      "coinfection___81325006":"0",
      "coinfection___8745002":"0",
      "coinfection___407479009":"0",
      "coinfection___407480007":"0",
      "coinfection___84101006":"0",
      "coinfection___233607000":"0",
      "coinfection___6415009":"0",
      "coinfection___1838001":"0",
      "coinfection___49872002":"0",
      "coinfection___442376007":"0",
      "coinfection___none":"0",
      "coinfection___oth":"0",
      "coinfection___unk":"0",
      "treatment_modality___685":"1",
      "treatment_modality___691":"0",
      "treatment_modality___694":"1",
      "treatment_modality___45215":"0",
      "treatment_modality___695":"0",
      "treatment_modality___14051":"0",
      "treatment_modality___58229":"0",
      "treatment_modality___45186":"0",
      "treatment_modality___oth":"0",
      "screening_form_complete": "2",
      "first_name": "Firas",
      "last_name": "Wehbe",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
      }
    ]
  RECORDS
        end

        it 'for future offsets set to 1 day', focus: false do
          @redcap_derived_date_death.offset_interval_days = 1
          @redcap_derived_date_death.offset_interval_direction = Redcap2omop::RedcapDerivedDate::OFFSET_INTERVAL_DIRECTION_FUTURE
          @redcap_derived_date_death.save!

          setup_specs(@records)
          expect(Redcap2omop::Death.count).to eq 0
          service.run

          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          person_1_death = Redcap2omop::Death.where(person_id: person_1.person_id).first
          expect(Redcap2omop::Person.where(person_source_value: @record_id_1).count).to eq 1
          expect(Redcap2omop::Death.where(person_id: person_1.person_id).count).to eq 1

          expect(person_1_death.death_type_concept_id).to eq @death_type_concept.concept_id
          expect(person_1_death.cause_concept_id).to eq @cause_of_death_concept_1.concept_id
          expect(person_1_death.death_date).to eq ((Date.parse(@ts_0_1) - @covid_19_redcap_variable_choices[@covid_19_dx_interval_choice_description_1]) - (@days_to_death_2_record_id_1 * 1 * 1))
        end

        it 'for past offsets set to 1 day', focus: false do
          @redcap_derived_date_death.offset_interval_days = 1
          @redcap_derived_date_death.offset_interval_direction = Redcap2omop::RedcapDerivedDate::OFFSET_INTERVAL_DIRECTION_PAST
          @redcap_derived_date_death.save!

          setup_specs(@records)
          expect(Redcap2omop::Death.count).to eq 0
          service.run

          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          person_1_death = Redcap2omop::Death.where(person_id: person_1.person_id).first
          expect(Redcap2omop::Person.where(person_source_value: @record_id_1).count).to eq 1
          expect(Redcap2omop::Death.where(person_id: person_1.person_id).count).to eq 1

          expect(person_1_death.death_type_concept_id).to eq @death_type_concept.concept_id
          expect(person_1_death.death_date).to eq ((Date.parse(@ts_0_1) - @covid_19_redcap_variable_choices[@covid_19_dx_interval_choice_description_1]) - (@days_to_death_2_record_id_1 * 1 * -1))
        end

        it 'for future offsets set to 2 days', focus: false do
          @redcap_derived_date_death.offset_interval_days = 2
          @redcap_derived_date_death.offset_interval_direction = Redcap2omop::RedcapDerivedDate::OFFSET_INTERVAL_DIRECTION_FUTURE
          @redcap_derived_date_death.save!

          setup_specs(@records)
          expect(Redcap2omop::Death.count).to eq 0
          service.run

          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          person_1_death = Redcap2omop::Death.where(person_id: person_1.person_id).first
          expect(Redcap2omop::Person.where(person_source_value: @record_id_1).count).to eq 1
          expect(Redcap2omop::Death.where(person_id: person_1.person_id).count).to eq 1

          expect(person_1_death.death_type_concept_id).to eq @death_type_concept.concept_id
          expect(person_1_death.death_date).to eq ((Date.parse(@ts_0_1) - @covid_19_redcap_variable_choices[@covid_19_dx_interval_choice_description_1]) - (@days_to_death_2_record_id_1 * 2 * 1))
        end

        it 'for past offsets set to 2 days', focus: false do
          @redcap_derived_date_death.offset_interval_days = 2
          @redcap_derived_date_death.offset_interval_direction = Redcap2omop::RedcapDerivedDate::OFFSET_INTERVAL_DIRECTION_PAST
          @redcap_derived_date_death.save!

          setup_specs(@records)
          expect(Redcap2omop::Death.count).to eq 0
          service.run

          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          person_1_death = Redcap2omop::Death.where(person_id: person_1.person_id).first
          expect(Redcap2omop::Person.where(person_source_value: @record_id_1).count).to eq 1
          expect(Redcap2omop::Death.where(person_id: person_1.person_id).count).to eq 1

          expect(person_1_death.death_type_concept_id).to eq @death_type_concept.concept_id
          expect(person_1_death.death_date).to eq ((Date.parse(@ts_0_1) - @covid_19_redcap_variable_choices[@covid_19_dx_interval_choice_description_1]) - (@days_to_death_2_record_id_1 * 2 * -1))
        end
      end

      it "can map categorical REDCap variable to an OMOP domain 'Measurement' entity", focus: false do
        redcap_data_dictionary = project.redcap_data_dictionaries.last

        #wbc_range
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'wbc_range', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        wbc_concept = Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'SNOMED', concept_code: '391558003').first
        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'screending_d').first
        redcap_variable.build_redcap_variable_map(concept_id: wbc_concept.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        redcap_variable.save!

        redcap_variable_choice_1 = redcap_variable.redcap_variable_choices.where(choice_description: "High").first
        wbc_range_concept_1 = Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '75540009').first
        redcap_variable_choice_1.build_redcap_variable_choice_map(concept_id: wbc_range_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice_1.save!

        redcap_variable_choice_2 = redcap_variable.redcap_variable_choices.where(choice_description: "Low").first
        wbc_range_concept_2 = Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'SNOMED', concept_code: '62482003').first
        redcap_variable_choice_2.build_redcap_variable_choice_map(concept_id: wbc_range_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice_2.save!

        redcap_variable_choice_3 = redcap_variable.redcap_variable_choices.where(choice_description: "Normal").first
        wbc_range_concept_3 = Redcap2omop::Concept.where(domain_id: 'Spec Disease Status', vocabulary_id: 'SNOMED', concept_code: '17621005').first
        redcap_variable_choice_3.build_redcap_variable_choice_map(concept_id: wbc_range_concept_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice_3.save!

        redcap_variable_choice_4 = redcap_variable.redcap_variable_choices.where(choice_description: "Not tested").first
        redcap_variable_choice_4.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice_4.save!

        redcap_variable_choice_5 = redcap_variable.redcap_variable_choices.where(choice_description: "Unknown").first
        redcap_variable_choice_5.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable_choice_5.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
        redcap_variable_choice_5.save!

        redcap_variable.save!

        record_id_1 = 'abc123'
        screening_d_1 = '2021-03-30'
        bmi_1 = '25'
records = <<-RECORDS
[
  {
    "record_id": "#{record_id_1}",
    "redcap_event_name": "baseline_arm_1",
    "redcap_repeat_instrument": "",
    "redcap_repeat_instance": "",
    "dx_year": "2020",
    "screending_d": "#{screening_d_1}",
    "urban_rural": "99",
    "bmi": "#{bmi_1}",
    "wbc_range": "#{redcap_variable_choice_1.choice_code_raw}",
    "screening_form_complete": "2",
    "first_name": "Firas",
    "last_name": "Wehbe",
    "dob": "1976-10-14",
    "gender": "3",
    "race___1": "0",
    "race___2": "1",
    "race___3": "0",
    "race___4": "0",
    "race___5": "0",
    "race___6": "1",
    "race___99": "0",
    "ethnicity": "2",
    "hcw": "1",
    "smoking_product___722495000": "0",
    "smoking_product___unk": "0",
    "smoking_product___oth": "0",
    "smoking_product___722496004": "1",
    "smoking_product___722498003": "0",
    "smoking_product___722497008": "1",
    "demographics_complete": "2",
    "v_d": "2020-10-23",
    "v_coordinator": "Michaela",
    "visit_information_complete": "2",
    "moca": "87",
    "mood": "100",
    "test_calc": "187",
    "clock_position_of_wound": "1",
    "visit_data_complete": "0",
    "m_d": "2020-10-23",
    "mri_coordinator": "Jayashri",
    "mri_information_complete": "0"
  }
]
RECORDS
        setup_specs(records)

        expect(Redcap2omop::Measurement.count).to eq 0
        service.run
        expect(Redcap2omop::Measurement.count).to eq 1
        expect(Redcap2omop::Measurement.first.concept.concept_id).to eq wbc_concept.concept_id
        expect(Redcap2omop::Measurement.first.measurement_date).to eq Date.parse(screening_d_1)
        expect(Redcap2omop::Measurement.first.value_as_concept_id).to eq wbc_range_concept_1.concept_id
      end

      it "can map numeric REDCap variable to an OMOP domain 'Measurement' entity", focus: false do
        redcap_data_dictionary = project.redcap_data_dictionaries.last
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'bmi', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        concept = Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'LOINC', concept_code: '39156-5').first
        redcap_variable.build_redcap_variable_map(concept_id: concept.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'screending_d').first
        redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        record_id_1 = 'abc123'
        screening_d_1 = '2021-03-30'
        bmi_1 = '25'
records = <<-RECORDS
[
  {
    "record_id": "#{record_id_1}",
    "redcap_event_name": "baseline_arm_1",
    "redcap_repeat_instrument": "",
    "redcap_repeat_instance": "",
    "dx_year": "2020",
    "screending_d": "#{screening_d_1}",
    "urban_rural": "99",
    "bmi": "#{bmi_1}",
    "screening_form_complete": "2",
    "first_name": "Firas",
    "last_name": "Wehbe",
    "dob": "1976-10-14",
    "gender": "3",
    "race___1": "0",
    "race___2": "1",
    "race___3": "0",
    "race___4": "0",
    "race___5": "0",
    "race___6": "1",
    "race___99": "0",
    "ethnicity": "2",
    "hcw": "1",
    "smoking_product___722495000": "0",
    "smoking_product___unk": "0",
    "smoking_product___oth": "0",
    "smoking_product___722496004": "1",
    "smoking_product___722498003": "0",
    "smoking_product___722497008": "1",
    "demographics_complete": "2",
    "v_d": "2020-10-23",
    "v_coordinator": "Michaela",
    "visit_information_complete": "2",
    "moca": "87",
    "mood": "100",
    "test_calc": "187",
    "clock_position_of_wound": "1",
    "visit_data_complete": "0",
    "m_d": "2020-10-23",
    "mri_coordinator": "Jayashri",
    "mri_information_complete": "0"
  }
]
RECORDS
        setup_specs(records)
        expect(Redcap2omop::Measurement.count).to eq 0
        service.run
        expect(Redcap2omop::Measurement.count).to eq 1
        expect(Redcap2omop::Measurement.first.concept.concept_id).to eq concept.concept_id
        expect(Redcap2omop::Measurement.first.measurement_date).to eq Date.parse(screening_d_1)
        expect(Redcap2omop::Measurement.first.value_as_number).to eq bmi_1.to_d
      end

      it "can map REDCap variable to an OMOP domain 'Condition' entity", focus: false do
        screening_d = '2021-03-30'
records = <<-RECORDS
[
  {
    "record_id": "abc123",
    "redcap_event_name": "baseline_arm_1",
    "redcap_repeat_instrument": "",
    "redcap_repeat_instance": "",
    "dx_year": "2020",
    "screending_d": "#{screening_d}",
    "screening_form_complete": "2",
    "first_name": "Firas",
    "last_name": "Wehbe",
    "dob": "1976-10-14",
    "gender": "3",
    "race___1": "0",
    "race___2": "1",
    "race___3": "0",
    "race___4": "0",
    "race___5": "0",
    "race___6": "1",
    "race___99": "0",
    "ethnicity": "2",
    "hcw": "1",
    "smoking_product___722495000": "0",
    "smoking_product___unk": "0",
    "smoking_product___oth": "0",
    "smoking_product___722496004": "1",
    "smoking_product___722498003": "0",
    "smoking_product___722497008": "1",
    "demographics_complete": "2",
    "v_d": "2020-10-23",
    "v_coordinator": "Michaela",
    "visit_information_complete": "2",
    "moca": "87",
    "mood": "100",
    "test_calc": "187",
    "clock_position_of_wound": "1",
    "visit_data_complete": "0",
    "m_d": "2020-10-23",
    "mri_coordinator": "Jayashri",
    "mri_information_complete": "0"
  }
]
RECORDS
        setup_specs(records)
        redcap_data_dictionary = project.redcap_data_dictionaries.last
        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dx_year', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        concept_code = '840539006'
        redcap_variable.build_redcap_variable_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: concept_code).first.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        omop_column = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first
        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'screending_d').first
        redcap_variable.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        redcap_variable.save!

        expect(Redcap2omop::ConditionOccurrence.count).to eq 0
        service.run
        expect(Redcap2omop::ConditionOccurrence.count).to eq 1
        expect(Redcap2omop::ConditionOccurrence.first.concept.concept_code).to eq concept_code
        expect(Redcap2omop::ConditionOccurrence.first.condition_start_date).to eq Date.parse(screening_d)
      end

      it 'can map a REDCap derived date from a base date choice REDCap variable', focus: false do
        redcap_data_dictionary = project.redcap_data_dictionaries.last
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

        redcap_derived_date_diagnosis_covid19 = Redcap2omop::RedcapDerivedDate.where(name: 'COVID-19 Diagnosis', base_date_redcap_variable: base_date_redcap_variable, offset_redcap_variable: offset_redcap_variable).first_or_create

        redcap_variable_choices.each do |k,v|
          redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: offset_redcap_variable.id, choice_description: k).first
          redcap_derived_date_diagnosis_covid19.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
        end
        redcap_derived_date_diagnosis_covid19.save!

        redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dx_year', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        covid_19_concept = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first
        redcap_variable.build_redcap_variable_map(concept_id: covid_19_concept.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
        redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first
        redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
        redcap_variable.save!

        record_id_1 = 'abc123'
        record_id_2 = 'abc456'
        screening_d_1 = '2021-03-30'
        screening_d_2 = '2021-04-30'
        ts_0_1 = '2021-04-07 12:46'
        ts_0_2 = '2021-06-01 10:00'
        @covid_19_dx_interval_choice_description_1 = 'Within the past 1 to 2 weeks'
        covid_19_dx_interval_choice_code_raw_1 = offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @covid_19_dx_interval_choice_description_1 }.choice_code_raw
        @covid_19_dx_interval_choice_description_2 = 'Within the past 8 to 12 weeks'
        covid_19_dx_interval_choice_code_raw_2 = offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @covid_19_dx_interval_choice_description_2 }.choice_code_raw
records = <<-RECORDS
[
  {
    "record_id": "#{record_id_1}",
    "redcap_event_name": "baseline_arm_1",
    "redcap_repeat_instrument": "",
    "redcap_repeat_instance": "",
    "ts_0":"#{ts_0_1}",
    "covid_19_dx_interval":"#{covid_19_dx_interval_choice_code_raw_1}",
    "dx_year": "2020",
    "screending_d": "#{screening_d_1}",
    "urban_rural": "1",
    "concomitant_meds___n02ba": "1",
    "concomitant_meds___rxcui_18631": "0",
    "concomitant_meds___rxcui_2393": "0",
    "concomitant_meds___rxcui_5521": "1",
    "concomitant_meds___oth": "0",
    "concomitant_meds___none": "0",
    "concomitant_meds___unk": "0",
    "covid_19_lab_type___94558_4":"1",
    "covid_19_lab_type___94746_5":"1",
    "covid_19_lab_type___94762_2":"0",
    "covid_19_lab_type___la14698_7":"0",
    "covid_19_lab_type___la4489_6":"0",
    "c19_complications_systemic___50960005":"0",
    "c19_complications_systemic___67406007":"1",
    "c19_complications_systemic___57653000":"0",
    "c19_complications_systemic___91302008":"1",
    "c19_complications_systemic___238147009":"0",
    "c19_complications_systemic___none":"0",
    "c19_complications_systemic___unk":"0",
    "coinfection___2429008":"1",
    "coinfection___709601002":"1",
    "coinfection___409822003":"0",
    "coinfection___414561005":"0",
    "coinfection___81325006":"0",
    "coinfection___8745002":"0",
    "coinfection___407479009":"0",
    "coinfection___407480007":"0",
    "coinfection___84101006":"0",
    "coinfection___233607000":"0",
    "coinfection___6415009":"0",
    "coinfection___1838001":"0",
    "coinfection___49872002":"0",
    "coinfection___442376007":"0",
    "coinfection___none":"0",
    "coinfection___oth":"0",
    "coinfection___unk":"0",
    "treatment_modality___685":"1",
    "treatment_modality___691":"0",
    "treatment_modality___694":"1",
    "treatment_modality___45215":"0",
    "treatment_modality___695":"0",
    "treatment_modality___14051":"0",
    "treatment_modality___58229":"0",
    "treatment_modality___45186":"0",
    "treatment_modality___oth":"0",
    "screening_form_complete": "2",
    "first_name": "Firas",
    "last_name": "Wehbe",
    "dob": "1976-10-14",
    "gender": "3",
    "race___1": "0",
    "race___2": "1",
    "race___3": "0",
    "race___4": "0",
    "race___5": "0",
    "race___6": "1",
    "race___99": "0",
    "ethnicity": "2",
    "hcw": "1",
    "smoking_product___722495000": "0",
    "smoking_product___unk": "0",
    "smoking_product___oth": "0",
    "smoking_product___722496004": "1",
    "smoking_product___722498003": "0",
    "smoking_product___722497008": "1",
    "demographics_complete": "2",
    "v_d": "2020-10-23",
    "v_coordinator": "Michaela",
    "visit_information_complete": "2",
    "moca": "87",
    "mood": "100",
    "test_calc": "187",
    "clock_position_of_wound": "1",
    "visit_data_complete": "0",
    "m_d": "2020-10-23",
    "mri_coordinator": "Jayashri",
    "mri_information_complete": "0"
  },
  {
    "record_id": "#{record_id_2}",
    "redcap_event_name": "baseline_arm_1",
    "redcap_repeat_instrument": "",
    "redcap_repeat_instance": "",
    "ts_0":"#{ts_0_2}",
    "covid_19_dx_interval":"#{covid_19_dx_interval_choice_code_raw_2}",
    "dx_year": "2020",
    "screending_d": "#{screening_d_2}",
    "urban_rural": "1",
    "concomitant_meds___n02ba": "1",
    "concomitant_meds___rxcui_18631": "0",
    "concomitant_meds___rxcui_2393": "0",
    "concomitant_meds___rxcui_5521": "1",
    "concomitant_meds___oth": "0",
    "concomitant_meds___none": "0",
    "concomitant_meds___unk": "0",
    "covid_19_lab_type___94558_4":"1",
    "covid_19_lab_type___94746_5":"1",
    "covid_19_lab_type___94762_2":"0",
    "covid_19_lab_type___la14698_7":"0",
    "covid_19_lab_type___la4489_6":"0",
    "c19_complications_systemic___50960005":"0",
    "c19_complications_systemic___67406007":"1",
    "c19_complications_systemic___57653000":"0",
    "c19_complications_systemic___91302008":"1",
    "c19_complications_systemic___238147009":"0",
    "c19_complications_systemic___none":"0",
    "c19_complications_systemic___unk":"0",
    "coinfection___2429008":"1",
    "coinfection___709601002":"1",
    "coinfection___409822003":"0",
    "coinfection___414561005":"0",
    "coinfection___81325006":"0",
    "coinfection___8745002":"0",
    "coinfection___407479009":"0",
    "coinfection___407480007":"0",
    "coinfection___84101006":"0",
    "coinfection___233607000":"0",
    "coinfection___6415009":"0",
    "coinfection___1838001":"0",
    "coinfection___49872002":"0",
    "coinfection___442376007":"0",
    "coinfection___none":"0",
    "coinfection___oth":"0",
    "coinfection___unk":"0",
    "treatment_modality___685":"1",
    "treatment_modality___691":"0",
    "treatment_modality___694":"1",
    "treatment_modality___45215":"0",
    "treatment_modality___695":"0",
    "treatment_modality___14051":"0",
    "treatment_modality___58229":"0",
    "treatment_modality___45186":"0",
    "treatment_modality___oth":"0",
    "screening_form_complete": "2",
    "first_name": "Firas",
    "last_name": "Wehbe",
    "dob": "1976-10-14",
    "gender": "3",
    "race___1": "0",
    "race___2": "1",
    "race___3": "0",
    "race___4": "0",
    "race___5": "0",
    "race___6": "1",
    "race___99": "0",
    "ethnicity": "2",
    "hcw": "1",
    "smoking_product___722495000": "0",
    "smoking_product___unk": "0",
    "smoking_product___oth": "0",
    "smoking_product___722496004": "1",
    "smoking_product___722498003": "0",
    "smoking_product___722497008": "1",
    "demographics_complete": "2",
    "v_d": "2020-10-23",
    "v_coordinator": "Michaela",
    "visit_information_complete": "2",
    "moca": "87",
    "mood": "100",
    "test_calc": "187",
    "clock_position_of_wound": "1",
    "visit_data_complete": "0",
    "m_d": "2020-10-23",
    "mri_coordinator": "Jayashri",
    "mri_information_complete": "0"
  }
]
RECORDS
        setup_specs(records)
        expect(Redcap2omop::ConditionOccurrence.count).to eq 0
        service.run

        person_1 = Redcap2omop::Person.where(person_source_value: record_id_1).first
        expect(Redcap2omop::ConditionOccurrence.where(person_id: person_1.person_id).count).to eq 1
        condition_occurrence = Redcap2omop::ConditionOccurrence.where(person_id: person_1.person_id).first
        expect(condition_occurrence.concept.concept_id).to eq covid_19_concept.concept_id
        expect(condition_occurrence.condition_start_date).to eq (Date.parse(ts_0_1) - redcap_variable_choices[@covid_19_dx_interval_choice_description_1])

        person_2 = Redcap2omop::Person.where(person_source_value: record_id_2).first
        expect(Redcap2omop::ConditionOccurrence.where(person_id: person_2.person_id).count).to eq 1
        condition_occurrence = Redcap2omop::ConditionOccurrence.where(person_id: person_2.person_id).first
        expect(condition_occurrence.concept.concept_id).to eq covid_19_concept.concept_id
        expect(condition_occurrence.condition_start_date).to eq (Date.parse(ts_0_2) - redcap_variable_choices[@covid_19_dx_interval_choice_description_2])
      end

      describe 'can map a REDCap derived date from a parent REDCap derived date' do
        before(:each) do
          redcap_data_dictionary = project.redcap_data_dictionaries.last
          base_date_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'ts_0', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          base_date_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
          base_date_redcap_variable.save!

          covid_19_offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'covid_19_dx_interval', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          covid_19_offset_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
          covid_19_offset_redcap_variable.save!

          @covid_19_redcap_variable_choices = {}
          @covid_19_redcap_variable_choices['Within the past week'] = 4
          @covid_19_redcap_variable_choices['Within the past 1 to 2 weeks'] = 11
          @covid_19_redcap_variable_choices['Within the past 2 to 4 weeks'] = 21
          @covid_19_redcap_variable_choices['Within the past 4 to 8 weeks'] = 42
          @covid_19_redcap_variable_choices['Within the past 8 to 12 weeks'] = 70
          @covid_19_redcap_variable_choices['Within the past 3 to 6 months'] = 135
          @covid_19_redcap_variable_choices['More than 6 months ago'] = 270
          @covid_19_redcap_variable_choices['Within the past 6 to 9 months'] = 225
          @covid_19_redcap_variable_choices['Within the past 9 to 12 months'] = 315
          @covid_19_redcap_variable_choices['More than 12 months ago'] = 450

          redcap_derived_date_diagnosis_covid_19 = Redcap2omop::RedcapDerivedDate.where(name: 'COVID-19 Diagnosis', base_date_redcap_variable: base_date_redcap_variable, offset_redcap_variable: covid_19_offset_redcap_variable).first_or_create

          @covid_19_redcap_variable_choices.each do |k,v|
            redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: covid_19_offset_redcap_variable.id, choice_description: k).first
            redcap_derived_date_diagnosis_covid_19.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
          end
          redcap_derived_date_diagnosis_covid_19.save!

          redcap_variable = Redcap2omop::RedcapVariable.where(name: 'dx_year', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          covid_19_concept = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '840539006').first
          redcap_variable.build_redcap_variable_map(concept_id: covid_19_concept.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first
          redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_covid_19, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable.save!

          cancer_offset_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'cancer_timing', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          cancer_offset_redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
          cancer_offset_redcap_variable.save!

          #Assume 30 days per month
          #Assume 365 days per year
          @cancer_redcap_variable_choices = {}
          @cancer_redcap_variable_choices['AFTER the COVID-19 diagnosis'] = -30
          @cancer_redcap_variable_choices['At the same time as COVID-19'] = 0
          @cancer_redcap_variable_choices['More than 5 years ago'] = 1825
          @cancer_redcap_variable_choices['Unknown'] = nil
          @cancer_redcap_variable_choices['Within the past 5 years'] = 913
          @cancer_redcap_variable_choices['Within the past year'] = 183

          redcap_derived_date_diagnosis_cancer = Redcap2omop::RedcapDerivedDate.where(name: 'Cancer Diagnosis', parent_redcap_derived_date: redcap_derived_date_diagnosis_covid_19, offset_redcap_variable: cancer_offset_redcap_variable).first_or_create
          @cancer_redcap_variable_choices.each do |k,v|
            redcap_variable_choice = Redcap2omop::RedcapVariableChoice.where(redcap_variable_id: cancer_offset_redcap_variable.id, choice_description: k).first
            redcap_derived_date_diagnosis_cancer.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: redcap_variable_choice,  offset_days: v)
          end
          redcap_derived_date_diagnosis_cancer.save!

          #redcap_variable
          redcap_variable_caner_type = Redcap2omop::RedcapVariable.where(name: 'cancer_type', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          redcap_variable_caner_type.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          redcap_variable_caner_type.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          redcap_variable_caner_type.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

          redcap_variable_cancer_type_choice_1 = redcap_variable_caner_type.redcap_variable_choices.where(choice_description: 'AL amyloidosis').first
          @cancer_concept_1 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '23132008').first
          redcap_variable_cancer_type_choice_1.build_redcap_variable_choice_map(concept_id: @cancer_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_cancer_type_choice_1.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_cancer_type_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_cancer_type_choice_1.save!

          redcap_variable_cancer_type_choice_2 = redcap_variable_caner_type.redcap_variable_choices.where(choice_description: 'Acute Leukemia').first
          @cancer_concept_2 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '91855006').first
          redcap_variable_cancer_type_choice_2.build_redcap_variable_choice_map(concept_id: @cancer_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_cancer_type_choice_2.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_cancer_type_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_cancer_type_choice_2.save!

          redcap_variable_cancer_type_choice_3 = redcap_variable_caner_type.redcap_variable_choices.where(choice_description: 'Acute lymphoblastic leukemia (ALL)').first
          @cancer_concept_3 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '91857003').first
          redcap_variable_cancer_type_choice_3.build_redcap_variable_choice_map(concept_id: @cancer_concept_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_cancer_type_choice_3.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_diagnosis_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          redcap_variable_cancer_type_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_cancer_type_choice_3.save!

          @record_id_1 = 'abc123'
          @record_id_2 = 'abc456'
          @record_id_3 = 'abc789'
          @record_id_4 = 'def123'
          screening_d_1 = '2021-03-30'
          screening_d_2 = '2021-04-30'
          screening_d_3 = '2021-01-30'
          screening_d_4 = '2021-02-30'
          @ts_0_1 = '2021-04-07 12:46'
          @ts_0_2 = '2021-06-01 10:00'
          @ts_0_3 = '2021-01-01 10:00'
          @ts_0_4 = '2021-01-15 10:00'

          @covid_19_dx_interval_choice_description_1 = 'Within the past 1 to 2 weeks'
          covid_19_dx_interval_choice_code_raw_1 = covid_19_offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @covid_19_dx_interval_choice_description_1 }.choice_code_raw
          @covid_19_dx_interval_choice_description_2 = 'Within the past 8 to 12 weeks'
          covid_19_dx_interval_choice_code_raw_2 = covid_19_offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @covid_19_dx_interval_choice_description_2 }.choice_code_raw
          @covid_19_dx_interval_choice_description_3 = 'More than 12 months ago'
          covid_19_dx_interval_choice_code_raw_3 = covid_19_offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @covid_19_dx_interval_choice_description_3 }.choice_code_raw

          @cancer_timing_choice_description_1 = 'More than 5 years ago'
          cancer_timing_choice_code_raw_1 = cancer_offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @cancer_timing_choice_description_1 }.choice_code_raw
          @cancer_timing_choice_description_2 = 'Within the past year'
          cancer_timing_choice_code_raw_2 = cancer_offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @cancer_timing_choice_description_2 }.choice_code_raw
          @cancer_timing_choice_description_3 = 'Unknown'
          cancer_timing_choice_code_raw_3 = cancer_offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @cancer_timing_choice_description_3 }.choice_code_raw
          @cancer_timing_choice_description_4 = 'AFTER the COVID-19 diagnosis'
          cancer_timing_choice_code_raw_4 = cancer_offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice|  redcap_variable_choice.choice_description ==  @cancer_timing_choice_description_4 }.choice_code_raw

  records = <<-RECORDS
  [
    {
      "record_id": "#{@record_id_1}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "ts_0":"#{@ts_0_1}",
      "covid_19_dx_interval":"#{covid_19_dx_interval_choice_code_raw_1}",
      "dx_year": "2020",
      "cancer_type": "#{redcap_variable_cancer_type_choice_1.choice_code_raw}",
      "cancer_timing": "#{cancer_timing_choice_code_raw_1}",
      "screending_d": "#{screening_d_1}",
      "urban_rural": "1",
      "concomitant_meds___n02ba": "1",
      "concomitant_meds___rxcui_18631": "0",
      "concomitant_meds___rxcui_2393": "0",
      "concomitant_meds___rxcui_5521": "1",
      "concomitant_meds___oth": "0",
      "concomitant_meds___none": "0",
      "concomitant_meds___unk": "0",
      "covid_19_lab_type___94558_4":"1",
      "covid_19_lab_type___94746_5":"1",
      "covid_19_lab_type___94762_2":"0",
      "covid_19_lab_type___la14698_7":"0",
      "covid_19_lab_type___la4489_6":"0",
      "c19_complications_systemic___50960005":"0",
      "c19_complications_systemic___67406007":"1",
      "c19_complications_systemic___57653000":"0",
      "c19_complications_systemic___91302008":"1",
      "c19_complications_systemic___238147009":"0",
      "c19_complications_systemic___none":"0",
      "c19_complications_systemic___unk":"0",
      "coinfection___2429008":"1",
      "coinfection___709601002":"1",
      "coinfection___409822003":"0",
      "coinfection___414561005":"0",
      "coinfection___81325006":"0",
      "coinfection___8745002":"0",
      "coinfection___407479009":"0",
      "coinfection___407480007":"0",
      "coinfection___84101006":"0",
      "coinfection___233607000":"0",
      "coinfection___6415009":"0",
      "coinfection___1838001":"0",
      "coinfection___49872002":"0",
      "coinfection___442376007":"0",
      "coinfection___none":"0",
      "coinfection___oth":"0",
      "coinfection___unk":"0",
      "treatment_modality___685":"1",
      "treatment_modality___691":"0",
      "treatment_modality___694":"1",
      "treatment_modality___45215":"0",
      "treatment_modality___695":"0",
      "treatment_modality___14051":"0",
      "treatment_modality___58229":"0",
      "treatment_modality___45186":"0",
      "treatment_modality___oth":"0",
      "screening_form_complete": "2",
      "first_name": "Firas",
      "last_name": "Wehbe",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    },
    {
      "record_id": "#{@record_id_2}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "ts_0":"#{@ts_0_2}",
      "covid_19_dx_interval":"#{covid_19_dx_interval_choice_code_raw_2}",
      "dx_year": "2020",
      "cancer_type": "#{redcap_variable_cancer_type_choice_2.choice_code_raw}",
      "cancer_timing": "#{cancer_timing_choice_code_raw_2}",
      "screending_d": "#{screening_d_2}",
      "urban_rural": "1",
      "concomitant_meds___n02ba": "1",
      "concomitant_meds___rxcui_18631": "0",
      "concomitant_meds___rxcui_2393": "0",
      "concomitant_meds___rxcui_5521": "1",
      "concomitant_meds___oth": "0",
      "concomitant_meds___none": "0",
      "concomitant_meds___unk": "0",
      "covid_19_lab_type___94558_4":"1",
      "covid_19_lab_type___94746_5":"1",
      "covid_19_lab_type___94762_2":"0",
      "covid_19_lab_type___la14698_7":"0",
      "covid_19_lab_type___la4489_6":"0",
      "c19_complications_systemic___50960005":"0",
      "c19_complications_systemic___67406007":"1",
      "c19_complications_systemic___57653000":"0",
      "c19_complications_systemic___91302008":"1",
      "c19_complications_systemic___238147009":"0",
      "c19_complications_systemic___none":"0",
      "c19_complications_systemic___unk":"0",
      "coinfection___2429008":"1",
      "coinfection___709601002":"1",
      "coinfection___409822003":"0",
      "coinfection___414561005":"0",
      "coinfection___81325006":"0",
      "coinfection___8745002":"0",
      "coinfection___407479009":"0",
      "coinfection___407480007":"0",
      "coinfection___84101006":"0",
      "coinfection___233607000":"0",
      "coinfection___6415009":"0",
      "coinfection___1838001":"0",
      "coinfection___49872002":"0",
      "coinfection___442376007":"0",
      "coinfection___none":"0",
      "coinfection___oth":"0",
      "coinfection___unk":"0",
      "treatment_modality___685":"1",
      "treatment_modality___691":"0",
      "treatment_modality___694":"1",
      "treatment_modality___45215":"0",
      "treatment_modality___695":"0",
      "treatment_modality___14051":"0",
      "treatment_modality___58229":"0",
      "treatment_modality___45186":"0",
      "treatment_modality___oth":"0",
      "screening_form_complete": "2",
      "first_name": "Firas",
      "last_name": "Wehbe",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    },
    {
      "record_id": "#{@record_id_3}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "ts_0":"#{@ts_0_3}",
      "covid_19_dx_interval":"#{covid_19_dx_interval_choice_code_raw_3}",
      "dx_year": "2020",
      "cancer_type": "#{redcap_variable_cancer_type_choice_3.choice_code_raw}",
      "cancer_timing": "#{cancer_timing_choice_code_raw_3}",
      "screending_d": "#{screening_d_3}",
      "urban_rural": "1",
      "concomitant_meds___n02ba": "1",
      "concomitant_meds___rxcui_18631": "0",
      "concomitant_meds___rxcui_2393": "0",
      "concomitant_meds___rxcui_5521": "1",
      "concomitant_meds___oth": "0",
      "concomitant_meds___none": "0",
      "concomitant_meds___unk": "0",
      "covid_19_lab_type___94558_4":"1",
      "covid_19_lab_type___94746_5":"1",
      "covid_19_lab_type___94762_2":"0",
      "covid_19_lab_type___la14698_7":"0",
      "covid_19_lab_type___la4489_6":"0",
      "c19_complications_systemic___50960005":"0",
      "c19_complications_systemic___67406007":"1",
      "c19_complications_systemic___57653000":"0",
      "c19_complications_systemic___91302008":"1",
      "c19_complications_systemic___238147009":"0",
      "c19_complications_systemic___none":"0",
      "c19_complications_systemic___unk":"0",
      "coinfection___2429008":"1",
      "coinfection___709601002":"1",
      "coinfection___409822003":"0",
      "coinfection___414561005":"0",
      "coinfection___81325006":"0",
      "coinfection___8745002":"0",
      "coinfection___407479009":"0",
      "coinfection___407480007":"0",
      "coinfection___84101006":"0",
      "coinfection___233607000":"0",
      "coinfection___6415009":"0",
      "coinfection___1838001":"0",
      "coinfection___49872002":"0",
      "coinfection___442376007":"0",
      "coinfection___none":"0",
      "coinfection___oth":"0",
      "coinfection___unk":"0",
      "treatment_modality___685":"1",
      "treatment_modality___691":"0",
      "treatment_modality___694":"1",
      "treatment_modality___45215":"0",
      "treatment_modality___695":"0",
      "treatment_modality___14051":"0",
      "treatment_modality___58229":"0",
      "treatment_modality___45186":"0",
      "treatment_modality___oth":"0",
      "screening_form_complete": "2",
      "first_name": "Firas",
      "last_name": "Wehbe",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    },
    {
      "record_id": "#{@record_id_4}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "ts_0":"#{@ts_0_4}",
      "covid_19_dx_interval":"#{covid_19_dx_interval_choice_code_raw_3}",
      "dx_year": "2020",
      "cancer_type": "#{redcap_variable_cancer_type_choice_3.choice_code_raw}",
      "cancer_timing": "#{cancer_timing_choice_code_raw_4}",
      "screending_d": "#{screening_d_4}",
      "urban_rural": "1",
      "concomitant_meds___n02ba": "1",
      "concomitant_meds___rxcui_18631": "0",
      "concomitant_meds___rxcui_2393": "0",
      "concomitant_meds___rxcui_5521": "1",
      "concomitant_meds___oth": "0",
      "concomitant_meds___none": "0",
      "concomitant_meds___unk": "0",
      "covid_19_lab_type___94558_4":"1",
      "covid_19_lab_type___94746_5":"1",
      "covid_19_lab_type___94762_2":"0",
      "covid_19_lab_type___la14698_7":"0",
      "covid_19_lab_type___la4489_6":"0",
      "c19_complications_systemic___50960005":"0",
      "c19_complications_systemic___67406007":"1",
      "c19_complications_systemic___57653000":"0",
      "c19_complications_systemic___91302008":"1",
      "c19_complications_systemic___238147009":"0",
      "c19_complications_systemic___none":"0",
      "c19_complications_systemic___unk":"0",
      "coinfection___2429008":"1",
      "coinfection___709601002":"1",
      "coinfection___409822003":"0",
      "coinfection___414561005":"0",
      "coinfection___81325006":"0",
      "coinfection___8745002":"0",
      "coinfection___407479009":"0",
      "coinfection___407480007":"0",
      "coinfection___84101006":"0",
      "coinfection___233607000":"0",
      "coinfection___6415009":"0",
      "coinfection___1838001":"0",
      "coinfection___49872002":"0",
      "coinfection___442376007":"0",
      "coinfection___none":"0",
      "coinfection___oth":"0",
      "coinfection___unk":"0",
      "treatment_modality___685":"1",
      "treatment_modality___691":"0",
      "treatment_modality___694":"1",
      "treatment_modality___45215":"0",
      "treatment_modality___695":"0",
      "treatment_modality___14051":"0",
      "treatment_modality___58229":"0",
      "treatment_modality___45186":"0",
      "treatment_modality___oth":"0",
      "screening_form_complete": "2",
      "first_name": "Firas",
      "last_name": "Wehbe",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    }
  ]
  RECORDS
          setup_specs(records)
          expect(Redcap2omop::ConditionOccurrence.count).to eq 0
          service.run
        end

        it 'for postive offsets', focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_1.person_id, condition_concept_id: @cancer_concept_1.concept_id).count).to eq 1
          condition_occurrence = Redcap2omop::ConditionOccurrence.where(person_id: person_1.person_id, condition_concept_id: @cancer_concept_1.concept_id).first
          expect(condition_occurrence.concept.concept_id).to eq @cancer_concept_1.concept_id
          expect(condition_occurrence.condition_start_date).to eq ((Date.parse(@ts_0_1) - @covid_19_redcap_variable_choices[@covid_19_dx_interval_choice_description_1]) - @cancer_redcap_variable_choices[@cancer_timing_choice_description_1])


          person_2 = Redcap2omop::Person.where(person_source_value: @record_id_2).first
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_2.person_id, condition_concept_id: @cancer_concept_2.concept_id).count).to eq 1
          condition_occurrence = Redcap2omop::ConditionOccurrence.where(person_id: person_2.person_id, condition_concept_id: @cancer_concept_2.concept_id).first
          expect(condition_occurrence.concept.concept_id).to eq @cancer_concept_2.concept_id
          expect(condition_occurrence.condition_start_date).to eq ((Date.parse(@ts_0_2) - @covid_19_redcap_variable_choices[@covid_19_dx_interval_choice_description_2]) - @cancer_redcap_variable_choices[@cancer_timing_choice_description_2])
        end

        it 'for negative offsets', focus: false do
          person_4 = Redcap2omop::Person.where(person_source_value: @record_id_4).first
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_4.person_id, condition_concept_id: @cancer_concept_3.concept_id).count).to eq 1
          condition_occurrence = Redcap2omop::ConditionOccurrence.where(person_id: person_4.person_id, condition_concept_id: @cancer_concept_3.concept_id).first
          expect(condition_occurrence.concept.concept_id).to eq @cancer_concept_3.concept_id
          expect(condition_occurrence.condition_start_date).to eq ((Date.parse(@ts_0_4) - @covid_19_redcap_variable_choices[@covid_19_dx_interval_choice_description_3]) - @cancer_redcap_variable_choices[@cancer_timing_choice_description_4])
        end

        it 'for nil offfsets', focus: false do
          person_3 = Redcap2omop::Person.where(person_source_value: @record_id_3).first
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_3.person_id, condition_concept_id: @cancer_concept_3.concept_id).count).to eq 0
        end
      end

      describe "can map a REDCap variable's different kind of children:" do
        before(:each) do
          #hiv_vl
          redcap_data_dictionary = project.redcap_data_dictionaries.last
          @redcap_variable_hiv_vl = Redcap2omop::RedcapVariable.where(name: 'hiv_vl', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'screending_d').first
          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
          omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'unit_concept_id'").first
          @hiv_vl_concept = Redcap2omop::Concept.where(domain_id: 'Measurement', concept_code: '413789001').first
          @redcap_variable_hiv_vl.build_redcap_variable_map(concept_id: @hiv_vl_concept.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_hiv_vl.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @unit_concept = Redcap2omop::Concept.where(domain_id: 'Unit', concept_code: '{copies}/mL').first
          @redcap_variable_hiv_vl.redcap_variable_child_maps.build(concept_id: @unit_concept.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_hiv_vl.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @redcap_variable_hiv_vl.save!

          @record_id_1 = 'abc123'
          @screening_d_1 = '2021-03-30'
          @hiv_vl = '200'

  records = <<-RECORDS
  [
    {
      "record_id": "#{@record_id_1}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "dx_year": "2020",
      "screending_d": "#{@screening_d_1}",
      "urban_rural": "99",
      "bmi": "25",
      "hiv_vl": "#{@hiv_vl}",
      "screening_form_complete": "2",
      "first_name": "Firas",
      "last_name": "Wehbe",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    }
  ]
  RECORDS
          setup_specs(records)
          expect(Redcap2omop::ConditionOccurrence.count).to eq 0
          expect(Redcap2omop::DrugExposure.count).to eq 0
          expect(Redcap2omop::Measurement.count).to eq 0
          service.run
        end

        it 'a REDCap variable', focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::Measurement.where(person_id: person_1.person_id).count).to eq 1
          expect(Redcap2omop::Measurement.where(person_id: person_1.person_id).first.concept.concept_id).to eq @hiv_vl_concept.concept_id
          expect(Redcap2omop::Measurement.where(person_id: person_1.person_id).first.measurement_date).to eq Date.parse(@screening_d_1)
          expect(Redcap2omop::Measurement.where(person_id: person_1.person_id).first.value_as_number).to eq @hiv_vl.to_d
        end

        it 'an OMOP concept', focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::Measurement.where(person_id: person_1.person_id).first.unit_concept_id).to eq @unit_concept.concept_id
        end
      end

      it "can map a REDCap variable within a repeating instrument", focus: false do
        redcap_data_dictionary = project.redcap_data_dictionaries.last
        @redcap_variable_moca = Redcap2omop::RedcapVariable.where(name: 'moca', redcap_data_dictionary_id: redcap_data_dictionary.id).first
        @moca_concept = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'LOINC', concept_code: '72172-0').first
        @redcap_variable_moca.build_redcap_variable_map(concept_id: @moca_concept.concept_id, map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT )
        @redcap_variable_moca.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
        @redcap_variable_moca.save!

        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_d').first
        omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
        @redcap_variable_moca.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        @redcap_variable_moca.save!

        other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'v_coordinator').first
        omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'provider_id'").first
        @redcap_variable_moca.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
        @redcap_variable_moca.save!

        record_id_1 = 'abc123'
        screening_d_1 = '2021-03-30'
        v_d_1 = '2020-09-23'
        v_d_2 = '2020-10-23'
        v_coordinator_1 = 'Bob'
        v_coordinator_2 = 'Michaela'
        moca_1 = '50'
        moca_2 = '60'
records = <<-RECORDS
[
  {
    "record_id": "#{record_id_1}",
    "redcap_event_name": "baseline_arm_1",
    "redcap_repeat_instrument": "",
    "redcap_repeat_instance": "",
    "dx_year": "2020",
    "screending_d": "#{screening_d_1}",
    "urban_rural": "",
    "bmi": "",
    "wbc_range": "",
    "screening_form_complete": "2",
    "first_name": "Firas",
    "last_name": "Wehbe",
    "dob": "1976-10-14",
    "gender": "3",
    "race___1": "0",
    "race___2": "1",
    "race___3": "0",
    "race___4": "0",
    "race___5": "0",
    "race___6": "1",
    "race___99": "0",
    "ethnicity": "2",
    "hcw": "1",
    "smoking_product___722495000": "0",
    "smoking_product___unk": "0",
    "smoking_product___oth": "0",
    "smoking_product___722496004": "1",
    "smoking_product___722498003": "0",
    "smoking_product___722497008": "1",
    "demographics_complete": "2",
    "v_d": "#{v_d_1}",
    "v_coordinator": "#{v_coordinator_1}",
    "visit_information_complete": "2",
    "moca": "",
    "mood": "",
    "test_calc": "",
    "clock_position_of_wound": "",
    "visit_data_complete": "0",
    "m_d": "",
    "mri_coordinator": "",
    "mri_information_complete": ""
  },
  {
    "record_id": "#{record_id_1}",
    "redcap_event_name": "follow_up_1_week_arm_1",
    "redcap_repeat_instrument": "",
    "redcap_repeat_instance": "",
    "dx_year": "",
    "screending_d": "",
    "urban_rural": "",
    "bmi": "",
    "wbc_range": "",
    "screening_form_complete": "",
    "first_name": "",
    "last_name": "",
    "dob": "",
    "gender": "",
    "race___1": "",
    "race___2": "",
    "race___3": "",
    "race___4": "",
    "race___5": "",
    "race___6": "",
    "race___99": "",
    "ethnicity": "",
    "hcw": "1",
    "smoking_product___722495000": "",
    "smoking_product___unk": "",
    "smoking_product___oth": "",
    "smoking_product___722496004": "",
    "smoking_product___722498003": "",
    "smoking_product___722497008": "",
    "demographics_complete": "",
    "v_d": "#{v_d_2}",
    "v_coordinator": "#{v_coordinator_2}",
    "visit_information_complete": "2",
    "moca": "",
    "mood": "",
    "test_calc": "",
    "clock_position_of_wound": "",
    "visit_data_complete": "0",
    "m_d": "",
    "mri_coordinator": "",
    "mri_information_complete": ""
  },
  {
    "record_id": "#{record_id_1}",
    "redcap_event_name": "follow_up_1_week_arm_1",
    "redcap_repeat_instrument": "visit_data",
    "redcap_repeat_instance": "1",
    "dx_year": "",
    "screending_d": "",
    "urban_rural": "",
    "bmi": "",
    "wbc_range": "",
    "screening_form_complete": "",
    "first_name": "",
    "last_name": "",
    "dob": "",
    "gender": "",
    "race___1": "",
    "race___2": "",
    "race___3": "",
    "race___4": "",
    "race___5": "",
    "race___6": "",
    "race___99": "",
    "ethnicity": "",
    "hcw": "1",
    "smoking_product___722495000": "",
    "smoking_product___unk": "",
    "smoking_product___oth": "",
    "smoking_product___722496004": "",
    "smoking_product___722498003": "",
    "smoking_product___722497008": "",
    "demographics_complete": "",
    "v_d": "",
    "v_coordinator": "",
    "visit_information_complete": "",
    "moca": "#{moca_1}",
    "mood": "",
    "test_calc": "",
    "clock_position_of_wound": "1",
    "visit_data_complete": "0",
    "m_d": "",
    "mri_coordinator": "",
    "mri_information_complete": ""
  } ,
  {
    "record_id": "#{record_id_1}",
    "redcap_event_name": "follow_up_1_week_arm_1",
    "redcap_repeat_instrument": "visit_data",
    "redcap_repeat_instance": "2",
    "dx_year": "",
    "screending_d": "",
    "urban_rural": "",
    "bmi": "",
    "wbc_range": "",
    "screening_form_complete": "",
    "first_name": "",
    "last_name": "",
    "dob": "",
    "gender": "",
    "race___1": "",
    "race___2": "",
    "race___3": "",
    "race___4": "",
    "race___5": "",
    "race___6": "",
    "race___99": "",
    "ethnicity": "",
    "hcw": "1",
    "smoking_product___722495000": "",
    "smoking_product___unk": "",
    "smoking_product___oth": "",
    "smoking_product___722496004": "",
    "smoking_product___722498003": "",
    "smoking_product___722497008": "",
    "demographics_complete": "",
    "v_d": "",
    "v_coordinator": "",
    "visit_information_complete": "",
    "moca": "#{moca_2}",
    "mood": "",
    "test_calc": "",
    "clock_position_of_wound": "1",
    "visit_data_complete": "0",
    "m_d": "",
    "mri_coordinator": "",
    "mri_information_complete": ""
  }
]
RECORDS
        setup_specs(records)

        expect(Redcap2omop::Observation.count).to eq 0
        service.run
        person_1 = Redcap2omop::Person.where(person_source_value: record_id_1).first
        expect(Redcap2omop::Observation.where(person_id: person_1.person_id).count).to eq 2
        observation = Redcap2omop::Observation.where(person_id: person_1.person_id, observation_concept_id: @moca_concept.concept_id, observation_date: Date.parse(v_d_2), value_as_number: moca_1.to_d).first
        expect(observation.concept.concept_id).to eq @moca_concept.concept_id
        expect(observation.observation_date).to eq Date.parse(v_d_2)
        expect(observation.value_as_number).to eq moca_1.to_d
        provider = Redcap2omop::Provider.where(provider_source_value: v_coordinator_2).first
        expect(observation.provider_id).to eq provider.provider_id

        observation = Redcap2omop::Observation.where(person_id: person_1.person_id, observation_concept_id: @moca_concept.concept_id, observation_date: Date.parse(v_d_2), value_as_number: moca_2.to_d).first
        expect(observation.concept.concept_id).to eq @moca_concept.concept_id
        expect(observation.observation_date).to eq Date.parse(v_d_2)
        expect(observation.value_as_number).to eq moca_2.to_d
        provider = Redcap2omop::Provider.where(provider_source_value: v_coordinator_2).first
        expect(observation.provider_id).to eq provider.provider_id
      end

      describe 'can map REDCap variable multiple choice variables to OMOP domain entities:' do
        before(:each) do
          #concomitant_meds
          redcap_data_dictionary = project.redcap_data_dictionaries.last
          @redcap_variable_concomitant_meds = Redcap2omop::RedcapVariable.where(name: 'concomitant_meds', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @redcap_variable_concomitant_meds.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'screending_d').first
          @redcap_variable_concomitant_meds.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @redcap_variable_concomitant_meds.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_start_date'").first
          omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'drug_exposure' AND redcap2omop_omop_columns.name = 'drug_exposure_end_date'").first

          @redcap_variable_concomitant_meds_choice_1 = @redcap_variable_concomitant_meds.redcap_variable_choices.where(choice_description: 'Aspirin').first
          @concomitant_meds_concept_1 = Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '1191').first
          @redcap_variable_concomitant_meds_choice_1.build_redcap_variable_choice_map(concept_id: @concomitant_meds_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_concomitant_meds_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_concomitant_meds_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_concomitant_meds_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_concomitant_meds_choice_1.save!

          @redcap_variable_concomitant_meds_choice_2 = @redcap_variable_concomitant_meds.redcap_variable_choices.where(choice_description: 'Azithromycin (Zithromax/Z-Pak)').first
          @concomitant_meds_concept_2 = Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '18631').first
          @redcap_variable_concomitant_meds_choice_2.build_redcap_variable_choice_map(concept_id: @concomitant_meds_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_concomitant_meds_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_concomitant_meds_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_concomitant_meds_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_concomitant_meds_choice_2.save!

          @redcap_variable_concomitant_meds_choice_3 = @redcap_variable_concomitant_meds.redcap_variable_choices.where(choice_description: 'Chloroquine').first
          @concomitant_meds_concept_3 = Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '2393').first
          @redcap_variable_concomitant_meds_choice_3.build_redcap_variable_choice_map(concept_id: @concomitant_meds_concept_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_concomitant_meds_choice_3.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_concomitant_meds_choice_3.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_concomitant_meds_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_concomitant_meds_choice_3.save!

          @redcap_variable_concomitant_meds_choice_4 = @redcap_variable_concomitant_meds.redcap_variable_choices.where(choice_description: 'Hydroxychloroquine (Plaquenil)').first
          @concomitant_meds_concept_4 = Redcap2omop::Concept.where(domain_id: 'Drug', vocabulary_id: 'RxNorm', concept_code: '5521').first
          @redcap_variable_concomitant_meds_choice_4.build_redcap_variable_choice_map(concept_id: @concomitant_meds_concept_4.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_concomitant_meds_choice_4.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_concomitant_meds_choice_4.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_concomitant_meds_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_concomitant_meds_choice_4.save!

          @redcap_variable_concomitant_meds_choice_5 = @redcap_variable_concomitant_meds.redcap_variable_choices.where(choice_description: 'Other').first
          @redcap_variable_concomitant_meds_choice_5.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_concomitant_meds_choice_5.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_concomitant_meds_choice_5.save!

          @redcap_variable_concomitant_meds_choice_6 = @redcap_variable_concomitant_meds.redcap_variable_choices.where(choice_description: 'None').first
          @redcap_variable_concomitant_meds_choice_6.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_concomitant_meds_choice_6.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_concomitant_meds_choice_6.save!

          @redcap_variable_concomitant_meds_choice_7 = @redcap_variable_concomitant_meds.redcap_variable_choices.where(choice_description: 'Unknown').first
          @redcap_variable_concomitant_meds_choice_7.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_concomitant_meds_choice_7.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_concomitant_meds_choice_7.save!

          #covid_19_lab_type
          @redcap_variable_covid_19_lab_type = Redcap2omop::RedcapVariable.where(name: 'covid_19_lab_type', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @redcap_variable_covid_19_lab_type.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          @redcap_variable_covid_19_lab_type.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @redcap_variable_covid_19_lab_type.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'measurement_date'").first
          omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'measurement' AND redcap2omop_omop_columns.name = 'value_as_concept_id'").first

          @redcap_variable_covid_19_lab_type_choice_1 = @redcap_variable_covid_19_lab_type.redcap_variable_choices.where(choice_description: 'Antigen test (ELISA)').first
          @covid_19_lab_type_concept_1 = Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'LOINC', concept_code: '94558-4').first
          @postive_concept = Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA6576-8').first
          Redcap2omop::Concept.where(domain_id: 'Meas Value', vocabulary_id: 'LOINC', concept_code: 'LA6576-8').first.concept_id
          @redcap_variable_covid_19_lab_type_choice_1.build_redcap_variable_choice_map(concept_id: @covid_19_lab_type_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_covid_19_lab_type_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_covid_19_lab_type_choice_1.redcap_variable_child_maps.build(concept_id: @postive_concept.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_covid_19_lab_type_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_covid_19_lab_type_choice_1.save!

          @redcap_variable_covid_19_lab_type_choice_2 = @redcap_variable_covid_19_lab_type.redcap_variable_choices.where(choice_description: 'PCR').first
          @covid_19_lab_type_concept_2 = Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'LOINC', concept_code: '94746-5').first
          @redcap_variable_covid_19_lab_type_choice_2.build_redcap_variable_choice_map(concept_id: @covid_19_lab_type_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_covid_19_lab_type_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_covid_19_lab_type_choice_2.redcap_variable_child_maps.build(concept_id: @postive_concept.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_covid_19_lab_type_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_covid_19_lab_type_choice_2.save!

          @redcap_variable_covid_19_lab_type_choice_3 = @redcap_variable_covid_19_lab_type.redcap_variable_choices.where(choice_description: 'Serology (antibodies to SARS-CoV-2)').first
          @covid_19_lab_type_concept_3 = Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'LOINC', concept_code: '94762-2').first
          @redcap_variable_covid_19_lab_type_choice_3.build_redcap_variable_choice_map(concept_id: @covid_19_lab_type_concept_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_covid_19_lab_type_choice_3.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_covid_19_lab_type_choice_3.redcap_variable_child_maps.build(concept_id: @postive_concept.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_covid_19_lab_type_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_covid_19_lab_type_choice_3.save!

          @redcap_variable_covid_19_lab_type_choice_4 = @redcap_variable_covid_19_lab_type.redcap_variable_choices.where(choice_description: 'Other').first
          @covid_19_lab_type_concept_4 = Redcap2omop::Concept.where(domain_id: 'Measurement', vocabulary_id: 'OMOP Extension', concept_code: 'OMOP4873969').first
          @redcap_variable_covid_19_lab_type_choice_4.build_redcap_variable_choice_map(concept_id: @covid_19_lab_type_concept_4.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_covid_19_lab_type_choice_4.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_covid_19_lab_type_choice_4.redcap_variable_child_maps.build(concept_id: @postive_concept.concept_id, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_covid_19_lab_type_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_covid_19_lab_type_choice_4.save!

          @redcap_variable_covid_19_lab_type_choice_5 = @redcap_variable_covid_19_lab_type.redcap_variable_choices.where(choice_description: 'Unknown').first
          @redcap_variable_covid_19_lab_type_choice_5.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_covid_19_lab_type_choice_5.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_covid_19_lab_type_choice_5.save!

          #c19_complications_systemic
          @redcap_variable_c19_complications_systemic = Redcap2omop::RedcapVariable.where(name: 'c19_complications_systemic', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @redcap_variable_c19_complications_systemic.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          @redcap_variable_c19_complications_systemic.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @redcap_variable_c19_complications_systemic.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

          @redcap_variable_c19_complications_systemic_choice_1 = @redcap_variable_c19_complications_systemic.redcap_variable_choices.where(choice_description: 'Bleeding').first
          @concept_c19_complications_systemic_1 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '43364001').first
          @redcap_variable_c19_complications_systemic_choice_1.build_redcap_variable_choice_map(concept_id: @concept_c19_complications_systemic_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_c19_complications_systemic_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_c19_complications_systemic_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_c19_complications_systemic_choice_1.save!

          @redcap_variable_c19_complications_systemic_choice_2 = @redcap_variable_c19_complications_systemic.redcap_variable_choices.where(choice_description: 'Disseminated intravascular coagulation (DIC)').first
          @concept_c19_complications_systemic_2 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '67406007').first
          @redcap_variable_c19_complications_systemic_choice_2.build_redcap_variable_choice_map(concept_id: @concept_c19_complications_systemic_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_c19_complications_systemic_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_c19_complications_systemic_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_c19_complications_systemic_choice_2.save!

          @redcap_variable_c19_complications_systemic_choice_3 = @redcap_variable_c19_complications_systemic.redcap_variable_choices.where(choice_description: 'Multiorgan failure').first
          @concept_c19_complications_systemic_3 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '57653000').first
          @redcap_variable_c19_complications_systemic_choice_3.build_redcap_variable_choice_map(concept_id: @concept_c19_complications_systemic_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_c19_complications_systemic_choice_3.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_c19_complications_systemic_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_c19_complications_systemic_choice_3.save!

          @redcap_variable_c19_complications_systemic_choice_4 = @redcap_variable_c19_complications_systemic.redcap_variable_choices.where(choice_description: 'Sepsis').first
          @concept_c19_complications_systemic_4 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '91302008').first
          @redcap_variable_c19_complications_systemic_choice_4.build_redcap_variable_choice_map(concept_id: @concept_c19_complications_systemic_4.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_c19_complications_systemic_choice_4.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_c19_complications_systemic_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_c19_complications_systemic_choice_4.save!

          @redcap_variable_c19_complications_systemic_choice_5 = @redcap_variable_c19_complications_systemic.redcap_variable_choices.where(choice_description: 'None').first
          @redcap_variable_c19_complications_systemic_choice_5.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_c19_complications_systemic_choice_5.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_c19_complications_systemic_choice_5.save!

          @redcap_variable_c19_complications_systemic_choice_6 = @redcap_variable_c19_complications_systemic.redcap_variable_choices.where(choice_description: 'Other').first
          @redcap_variable_c19_complications_systemic_choice_6.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_c19_complications_systemic_choice_6.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_c19_complications_systemic_choice_6.save!

          @redcap_variable_c19_complications_systemic_choice_7 = @redcap_variable_c19_complications_systemic.redcap_variable_choices.where(choice_description: 'Unknown').first
          @redcap_variable_c19_complications_systemic_choice_7.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_c19_complications_systemic_choice_7.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_c19_complications_systemic_choice_7.save!

          #coinfection
          @redcap_variable_coinfection = Redcap2omop::RedcapVariable.where(name: 'coinfection', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @redcap_variable_coinfection.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          @redcap_variable_coinfection.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first
          omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first

          @redcap_variable_coinfection_choice_1 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Aspergillus culture-confirmed').first
          @coinfection_concept_1 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '2429008').first
          @redcap_variable_coinfection_choice_1.build_redcap_variable_choice_map(concept_id: @coinfection_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_1.save!

          @redcap_variable_coinfection_choice_2 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Aspergillus suspected (galactomannan positive)').first
          @coinfection_concept_2 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '709601002').first
          @redcap_variable_coinfection_choice_2.build_redcap_variable_choice_map(concept_id: @coinfection_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_2.save!

          @redcap_variable_coinfection_choice_3 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Bacterial infection, NOS').first
          @coinfection_concept_3 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '409822003').first
          @redcap_variable_coinfection_choice_3.build_redcap_variable_choice_map(concept_id: @coinfection_concept_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_3.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_3.save!

          @redcap_variable_coinfection_choice_4 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Fungal, NOS').first
          @coinfection_concept_4 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '414561005').first
          @redcap_variable_coinfection_choice_4.build_redcap_variable_choice_map(concept_id: @coinfection_concept_4.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_4.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_4.save!

          @redcap_variable_coinfection_choice_5 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Gram-negative bacteria, NOS').first
          @coinfection_concept_5 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '81325006').first
          @redcap_variable_coinfection_choice_5.build_redcap_variable_choice_map(concept_id: @coinfection_concept_5.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_5.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_5.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_5.save!

          @redcap_variable_coinfection_choice_6 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Gram-positive bacteria, NOS').first
          @coinfection_concept_6 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '8745002').first
          @redcap_variable_coinfection_choice_6.build_redcap_variable_choice_map(concept_id: @coinfection_concept_6.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_6.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_6.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_6.save!

          @redcap_variable_coinfection_choice_7 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Influenza A').first
          @coinfection_concept_7 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '407479009').first
          @redcap_variable_coinfection_choice_7.build_redcap_variable_choice_map(concept_id: @coinfection_concept_7.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_7.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_7.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_7.save!

          @redcap_variable_coinfection_choice_8 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Influenza B').first
          @coinfection_concept_8 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '407480007').first
          @redcap_variable_coinfection_choice_8.build_redcap_variable_choice_map(concept_id: @coinfection_concept_8.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_8.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_8.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_8.save!

          @redcap_variable_coinfection_choice_9 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Ordinary coronavirus, NOS').first
          @coinfection_concept_9 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '84101006').first
          @redcap_variable_coinfection_choice_9.build_redcap_variable_choice_map(concept_id: @coinfection_concept_9.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_9.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_9.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_9.save!

          @redcap_variable_coinfection_choice_10 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Pneumococcal pneumonia').first
          @coinfection_concept_10 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '233607000').first
          @redcap_variable_coinfection_choice_10.build_redcap_variable_choice_map(concept_id: @coinfection_concept_10.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_10.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_10.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_10.save!

          @redcap_variable_coinfection_choice_11 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'RSV').first
          @coinfection_concept_11 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '6415009').first
          @redcap_variable_coinfection_choice_11.build_redcap_variable_choice_map(concept_id: @coinfection_concept_11.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_11.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_11.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_11.save!

          @redcap_variable_coinfection_choice_12 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Rhinovirus').first
          @coinfection_concept_12 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '1838001').first
          @redcap_variable_coinfection_choice_12.build_redcap_variable_choice_map(concept_id: @coinfection_concept_12.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_12.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_12.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_12.save!

          @redcap_variable_coinfection_choice_13 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Viral, NOS').first
          @coinfection_concept_13 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '49872002').first
          @redcap_variable_coinfection_choice_13.build_redcap_variable_choice_map(concept_id: @coinfection_concept_13.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_13.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_coinfection_choice_13.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_13.save!

          @redcap_variable_coinfection_choice_14 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Tests are pending').first
          @redcap_variable_coinfection_choice_14.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_14.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_14.save!

          @redcap_variable_coinfection_choice_15 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'None').first
          @redcap_variable_coinfection_choice_15.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_15.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_15.save!

          @redcap_variable_coinfection_choice_16 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Other').first
          @redcap_variable_coinfection_choice_16.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_16.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_16.save!

          @redcap_variable_coinfection_choice_17 = @redcap_variable_coinfection.redcap_variable_choices.where(choice_description: 'Unknown').first
          @redcap_variable_coinfection_choice_17.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_coinfection_choice_17.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_coinfection_choice_17.save!

          #treatment_modality
          @redcap_variable_treatment_modality = Redcap2omop::RedcapVariable.where(name: 'treatment_modality', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @redcap_variable_treatment_modality.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          @redcap_variable_treatment_modality.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @redcap_variable_treatment_modality.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

          @redcap_variable_treatment_modality_choice_1 = @redcap_variable_treatment_modality.redcap_variable_choices.where(choice_description: 'Cytotoxic chemotherapy').first
          @treatment_modality_concept_1 = Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '367336001').first
          @redcap_variable_treatment_modality_choice_1.build_redcap_variable_choice_map(concept_id: @treatment_modality_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_treatment_modality_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_treatment_modality_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_treatment_modality_choice_1.save!

          @redcap_variable_treatment_modality_choice_2 = @redcap_variable_treatment_modality.redcap_variable_choices.where(choice_description: 'Endocrine (Hormone) therapy').first
          @treatment_modality_concept_2 = Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '169413002').first
          @redcap_variable_treatment_modality_choice_2.build_redcap_variable_choice_map(concept_id: @treatment_modality_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_treatment_modality_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_treatment_modality_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_treatment_modality_choice_2.save!

          @redcap_variable_treatment_modality_choice_3 = @redcap_variable_treatment_modality.redcap_variable_choices.where(choice_description: 'Immunotherapy').first
          @treatment_modality_concept_3 = Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '76334006').first
          @redcap_variable_treatment_modality_choice_3.build_redcap_variable_choice_map(concept_id: @treatment_modality_concept_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_treatment_modality_choice_3.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_treatment_modality_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_treatment_modality_choice_3.save!

          @redcap_variable_treatment_modality_choice_4 = @redcap_variable_treatment_modality.redcap_variable_choices.where(choice_description: 'Intravesicular therapy (e.g., BCG)').first
          @treatment_modality_concept_4 = Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '42284007').first
          @redcap_variable_treatment_modality_choice_4.build_redcap_variable_choice_map(concept_id: @treatment_modality_concept_4.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_treatment_modality_choice_4.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_treatment_modality_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_treatment_modality_choice_4.save!

          @redcap_variable_treatment_modality_choice_5 = @redcap_variable_treatment_modality.redcap_variable_choices.where(choice_description: 'Radiotherapy').first
          @treatment_modality_concept_5 = Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '33195004').first
          @redcap_variable_treatment_modality_choice_5.build_redcap_variable_choice_map(concept_id: @treatment_modality_concept_5.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_treatment_modality_choice_5.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_treatment_modality_choice_5.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_treatment_modality_choice_5.save!

          @redcap_variable_treatment_modality_choice_6 = @redcap_variable_treatment_modality.redcap_variable_choices.where(choice_description: 'Surgery').first
          @treatment_modality_concept_6 = Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '387713003').first
          @redcap_variable_treatment_modality_choice_6.build_redcap_variable_choice_map(concept_id: @treatment_modality_concept_6.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_treatment_modality_choice_6.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_treatment_modality_choice_6.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_treatment_modality_choice_6.save!

          # come back
          # this is not the right kind of semantic type
          # redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_description: 'Targeted therapy').first
          # redcap_variable_choice.build_redcap_variable_choice_map(concept_id: Redcap2omop::Concept.where(domain_id: 'Regimen', vocabulary_id: 'HemOnc', concept_code: '18701').first.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          # redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: redcap_derived_date_treatment_cancer, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE)
          # redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          # redcap_variable_choice.save!

          @redcap_variable_treatment_modality_choice_7 = @redcap_variable_treatment_modality.redcap_variable_choices.where(choice_description: 'Transplant/Cellular therapy').first
          @treatment_modality_concept_7 = Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '77465005').first
          @redcap_variable_treatment_modality_choice_7.build_redcap_variable_choice_map(concept_id: @treatment_modality_concept_7.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_treatment_modality_choice_7.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_treatment_modality_choice_7.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_treatment_modality_choice_7.save!

          @redcap_variable_treatment_modality_choice_8 = @redcap_variable_treatment_modality.redcap_variable_choices.where(choice_description: 'Other').first
          @redcap_variable_treatment_modality_choice_8.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_treatment_modality_choice_8.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_treatment_modality_choice_8.save!

          @record_id_1 = 'abc123'
          @screening_d_1 = '2021-03-30'
          @record_id_2 = 'abc456'
          @screening_d_2 = '2021-04-30'

  records = <<-RECORDS
  [
    {
      "record_id": "#{@record_id_1}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "dx_year": "2020",
      "screending_d": "#{@screening_d_1}",
      "urban_rural": "1",
      "concomitant_meds___n02ba": "1",
      "concomitant_meds___rxcui_18631": "0",
      "concomitant_meds___rxcui_2393": "0",
      "concomitant_meds___rxcui_5521": "1",
      "concomitant_meds___oth": "0",
      "concomitant_meds___none": "0",
      "concomitant_meds___unk": "0",
      "covid_19_lab_type___94558_4":"1",
      "covid_19_lab_type___94746_5":"1",
      "covid_19_lab_type___94762_2":"0",
      "covid_19_lab_type___la14698_7":"0",
      "covid_19_lab_type___la4489_6":"0",
      "c19_complications_systemic___50960005":"0",
      "c19_complications_systemic___67406007":"1",
      "c19_complications_systemic___57653000":"0",
      "c19_complications_systemic___91302008":"1",
      "c19_complications_systemic___238147009":"0",
      "c19_complications_systemic___none":"0",
      "c19_complications_systemic___unk":"0",
      "coinfection___2429008":"1",
      "coinfection___709601002":"1",
      "coinfection___409822003":"0",
      "coinfection___414561005":"0",
      "coinfection___81325006":"0",
      "coinfection___8745002":"0",
      "coinfection___407479009":"0",
      "coinfection___407480007":"0",
      "coinfection___84101006":"0",
      "coinfection___233607000":"0",
      "coinfection___6415009":"0",
      "coinfection___1838001":"0",
      "coinfection___49872002":"0",
      "coinfection___442376007":"0",
      "coinfection___none":"0",
      "coinfection___oth":"0",
      "coinfection___unk":"0",
      "treatment_modality___685":"1",
      "treatment_modality___691":"0",
      "treatment_modality___694":"1",
      "treatment_modality___45215":"0",
      "treatment_modality___695":"0",
      "treatment_modality___14051":"0",
      "treatment_modality___58229":"0",
      "treatment_modality___45186":"0",
      "treatment_modality___oth":"0",
      "screening_form_complete": "2",
      "first_name": "Firas",
      "last_name": "Wehbe",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    },
    {
      "record_id": "#{@record_id_2}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "dx_year": "2020",
      "screending_d": "#{@screening_d_2}",
      "urban_rural": "1",
      "concomitant_meds___n02ba": "0",
      "concomitant_meds___rxcui_18631": "1",
      "concomitant_meds___rxcui_2393": "1",
      "concomitant_meds___rxcui_5521": "0",
      "concomitant_meds___oth": "0",
      "concomitant_meds___none": "0",
      "concomitant_meds___unk": "0",
      "covid_19_lab_type___94558_4":"0",
      "covid_19_lab_type___94746_5":"0",
      "covid_19_lab_type___94762_2":"1",
      "covid_19_lab_type___la14698_7":"1",
      "covid_19_lab_type___la4489_6":"0",
      "c19_complications_systemic___50960005":"0",
      "c19_complications_systemic___67406007":"0",
      "c19_complications_systemic___57653000":"0",
      "c19_complications_systemic___91302008":"1",
      "c19_complications_systemic___238147009":"1",
      "c19_complications_systemic___none":"0",
      "c19_complications_systemic___unk":"0",
      "coinfection___2429008":"0",
      "coinfection___709601002":"0",
      "coinfection___409822003":"1",
      "coinfection___414561005":"1",
      "coinfection___81325006":"0",
      "coinfection___8745002":"0",
      "coinfection___407479009":"0",
      "coinfection___407480007":"0",
      "coinfection___84101006":"0",
      "coinfection___233607000":"0",
      "coinfection___6415009":"0",
      "coinfection___1838001":"0",
      "coinfection___49872002":"0",
      "coinfection___442376007":"0",
      "coinfection___none":"0",
      "coinfection___oth":"0",
      "coinfection___unk":"0",
      "treatment_modality___685":"0",
      "treatment_modality___691":"1",
      "treatment_modality___694":"0",
      "treatment_modality___45215":"0",
      "treatment_modality___695":"1",
      "treatment_modality___14051":"0",
      "treatment_modality___58229":"0",
      "treatment_modality___45186":"0",
      "treatment_modality___oth":"0",
      "screening_form_complete": "2",
      "first_name": "Firas",
      "last_name": "Wehbe",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    }
  ]
  RECORDS
          setup_specs(records)
          expect(Redcap2omop::ConditionOccurrence.count).to eq 0
          expect(Redcap2omop::DrugExposure.count).to eq 0
          expect(Redcap2omop::Observation.count).to eq 0
          expect(Redcap2omop::Measurement.count).to eq 0
          expect(Redcap2omop::ProcedureOccurrence.count).to eq 0
          service.run
        end

        it "'ConditionOccurrence'", focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_1.person_id).count).to eq 2

          condition_occurrence = Redcap2omop::ConditionOccurrence.where(person_id: person_1.person_id, condition_concept_id: @concept_c19_complications_systemic_2.concept_id).first
          expect(condition_occurrence.concept.concept_id).to eq @concept_c19_complications_systemic_2.concept_id
          expect(condition_occurrence.condition_start_date).to eq Date.parse(@screening_d_1)

          condition_occurrence = Redcap2omop::ConditionOccurrence.where(person_id: person_1.person_id, condition_concept_id: @concept_c19_complications_systemic_4.concept_id).first
          expect(condition_occurrence.concept.concept_id).to eq @concept_c19_complications_systemic_4.concept_id
          expect(condition_occurrence.condition_start_date).to eq Date.parse(@screening_d_1)

          person_2 = Redcap2omop::Person.where(person_source_value: @record_id_2).first
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_2.person_id).count).to eq 1
          condition_occurrence = Redcap2omop::ConditionOccurrence.where(person_id: person_2.person_id, condition_concept_id: @concept_c19_complications_systemic_4.concept_id).first
          expect(condition_occurrence.concept.concept_id).to eq @concept_c19_complications_systemic_4.concept_id
          expect(condition_occurrence.condition_start_date).to eq Date.parse(@screening_d_2)
        end

        it "'DrugExposure'", focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::DrugExposure.where(person_id: person_1.person_id).count).to eq 2

          drug_exposure = Redcap2omop::DrugExposure.where(person_id: person_1.person_id, drug_concept_id: @concomitant_meds_concept_1.concept_id).first
          expect(drug_exposure.concept.concept_id).to eq @concomitant_meds_concept_1.concept_id
          expect(drug_exposure.drug_exposure_start_date).to eq Date.parse(@screening_d_1)
          expect(drug_exposure.drug_exposure_end_date).to eq Date.parse(@screening_d_1)

          drug_exposure = Redcap2omop::DrugExposure.where(person_id: person_1.person_id, drug_concept_id: @concomitant_meds_concept_4.concept_id).first
          expect(drug_exposure.concept.concept_id).to eq @concomitant_meds_concept_4.concept_id
          expect(drug_exposure.drug_exposure_start_date).to eq Date.parse(@screening_d_1)
          expect(drug_exposure.drug_exposure_end_date).to eq Date.parse(@screening_d_1)

          person_2 = Redcap2omop::Person.where(person_source_value: @record_id_2).first
          expect(Redcap2omop::DrugExposure.where(person_id: person_2.person_id).count).to eq 2
          drug_exposure = Redcap2omop::DrugExposure.where(person_id: person_2.person_id, drug_concept_id: @concomitant_meds_concept_2.concept_id).first
          expect(drug_exposure.concept.concept_id).to eq @concomitant_meds_concept_2.concept_id
          expect(drug_exposure.drug_exposure_start_date).to eq Date.parse(@screening_d_2)
          expect(drug_exposure.drug_exposure_end_date).to eq Date.parse(@screening_d_2)

          drug_exposure = Redcap2omop::DrugExposure.where(person_id: person_2.person_id, drug_concept_id: @concomitant_meds_concept_3.concept_id).first
          expect(drug_exposure.concept.concept_id).to eq @concomitant_meds_concept_3.concept_id
          expect(drug_exposure.drug_exposure_start_date).to eq Date.parse(@screening_d_2)
          expect(drug_exposure.drug_exposure_end_date).to eq Date.parse(@screening_d_2)
        end

        it "'Observation'", focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::Observation.where(person_id: person_1.person_id).count).to eq 2

          observation = Redcap2omop::Observation.where(person_id: person_1.person_id, observation_concept_id: @coinfection_concept_1.concept_id).first
          expect(observation.concept.concept_id).to eq @coinfection_concept_1.concept_id
          expect(observation.value_as_concept_id).to be_nil
          expect(observation.observation_date).to eq Date.parse(@screening_d_1)

          observation = Redcap2omop::Observation.where(person_id: person_1.person_id, observation_concept_id: @coinfection_concept_2.concept_id).first
          expect(observation.concept.concept_id).to eq @coinfection_concept_2.concept_id
          expect(observation.value_as_concept_id).to be_nil
          expect(observation.observation_date).to eq Date.parse(@screening_d_1)

          person_2 = Redcap2omop::Person.where(person_source_value: @record_id_2).first
          expect(Redcap2omop::Observation.where(person_id: person_2.person_id).count).to eq 2
          observation = Redcap2omop::Observation.where(person_id: person_2.person_id, observation_concept_id: @coinfection_concept_3.concept_id).first
          expect(observation.concept.concept_id).to eq @coinfection_concept_3.concept_id
          expect(observation.value_as_concept_id).to be_nil
          expect(observation.observation_date).to eq Date.parse(@screening_d_2)

          observation = Redcap2omop::Observation.where(person_id: person_2.person_id, observation_concept_id: @coinfection_concept_4.concept_id).first
          expect(observation.concept.concept_id).to eq @coinfection_concept_4.concept_id
          expect(observation.value_as_concept_id).to be_nil
          expect(observation.observation_date).to eq Date.parse(@screening_d_2)
        end

        it "'Measurement'", focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::Measurement.where(person_id: person_1.person_id).count).to eq 2

          measurement = Redcap2omop::Measurement.where(person_id: person_1.person_id, measurement_concept_id: @covid_19_lab_type_concept_1.concept_id).first
          expect(measurement.concept.concept_id).to eq @covid_19_lab_type_concept_1.concept_id
          expect(measurement.value_as_concept_id).to eq @postive_concept.concept_id
          expect(measurement.measurement_date).to eq Date.parse(@screening_d_1)

          measurement = Redcap2omop::Measurement.where(person_id: person_1.person_id, measurement_concept_id: @covid_19_lab_type_concept_2.concept_id).first
          expect(measurement.concept.concept_id).to eq @covid_19_lab_type_concept_2.concept_id
          expect(measurement.value_as_concept_id).to eq @postive_concept.concept_id
          expect(measurement.measurement_date).to eq Date.parse(@screening_d_1)

          person_2 = Redcap2omop::Person.where(person_source_value: @record_id_2).first
          expect(Redcap2omop::Measurement.where(person_id: person_2.person_id).count).to eq 2
          measurement = Redcap2omop::Measurement.where(person_id: person_2.person_id, measurement_concept_id: @covid_19_lab_type_concept_3.concept_id).first
          expect(measurement.concept.concept_id).to eq @covid_19_lab_type_concept_3.concept_id
          expect(measurement.value_as_concept_id).to eq @postive_concept.concept_id
          expect(measurement.measurement_date).to eq Date.parse(@screening_d_2)

          measurement = Redcap2omop::Measurement.where(person_id: person_2.person_id, measurement_concept_id: @covid_19_lab_type_concept_4.concept_id).first
          expect(measurement.concept.concept_id).to eq @covid_19_lab_type_concept_4.concept_id
          expect(measurement.value_as_concept_id).to eq @postive_concept.concept_id
          expect(measurement.measurement_date).to eq Date.parse(@screening_d_2)
        end

        it "'ProcedureOccurrence'", focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::ProcedureOccurrence.where(person_id: person_1.person_id).count).to eq 2
          procedure_occurrence = Redcap2omop::ProcedureOccurrence.where(person_id: person_1.person_id, procedure_concept_id: @treatment_modality_concept_1.concept_id).first
          expect(procedure_occurrence.concept.concept_id).to eq @treatment_modality_concept_1.concept_id
          expect(procedure_occurrence.procedure_date).to eq Date.parse(@screening_d_1)

          procedure_occurrence = Redcap2omop::ProcedureOccurrence.where(person_id: person_1.person_id, procedure_concept_id: @treatment_modality_concept_3.concept_id).first
          expect(procedure_occurrence.concept.concept_id).to eq @treatment_modality_concept_3.concept_id
          expect(procedure_occurrence.procedure_date).to eq Date.parse(@screening_d_1)

          person_2 = Redcap2omop::Person.where(person_source_value: @record_id_2).first
          expect(Redcap2omop::ProcedureOccurrence.where(person_id: person_2.person_id).count).to eq 2
          procedure_occurrence = Redcap2omop::ProcedureOccurrence.where(person_id: person_2.person_id, procedure_concept_id: @treatment_modality_concept_2.concept_id).first
          expect(procedure_occurrence.concept.concept_id).to eq @treatment_modality_concept_2.concept_id
          expect(procedure_occurrence.procedure_date).to eq Date.parse(@screening_d_2)

          procedure_occurrence = Redcap2omop::ProcedureOccurrence.where(person_id: person_2.person_id, procedure_concept_id: @treatment_modality_concept_5.concept_id).first
          expect(procedure_occurrence.concept.concept_id).to eq @treatment_modality_concept_5.concept_id
          expect(procedure_occurrence.procedure_date).to eq Date.parse(@screening_d_2)
        end
        end
      end

      describe 'can map REDCap variable single choice variables to OMOP domain entities:' do
        before(:each) do
          #urban_rural
          redcap_data_dictionary = project.redcap_data_dictionaries.last
          @redcap_variable_urban_rural = Redcap2omop::RedcapVariable.where(name: 'urban_rural', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          other_redcap_variable = Redcap2omop::RedcapVariable.where(name: 'screending_d').first
          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'observation' AND redcap2omop_omop_columns.name = 'observation_date'").first
          @redcap_variable_urban_rural.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          @redcap_variable_urban_rural.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @redcap_variable_urban_rural.save!

          @redcap_variable_urban_rural_choice_1 = @redcap_variable_urban_rural.redcap_variable_choices.where(choice_description: 'Urban (city)').first
          @urban_rural_concept_1 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '78153003').first
          @redcap_variable_urban_rural_choice_1.build_redcap_variable_choice_map(concept_id: @urban_rural_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_urban_rural_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_urban_rural_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_urban_rural_choice_1.save!

          @redcap_variable_urban_rural_choice_2 = @redcap_variable_urban_rural.redcap_variable_choices.where(choice_description: 'Suburban (town, suburbs)').first
          @urban_rural_concept_2 = Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '62709005').first
          @redcap_variable_urban_rural_choice_2.build_redcap_variable_choice_map(concept_id: @urban_rural_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_urban_rural_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_urban_rural_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_urban_rural_choice_2.save!

          @redcap_variable_urban_rural_choice_3 = @redcap_variable_urban_rural.redcap_variable_choices.where(choice_description: 'Rural (country)').first
          @urban_rural_concept_3 =  Redcap2omop::Concept.where(domain_id: 'Observation', vocabulary_id: 'SNOMED', concept_code: '5794003').first
          @redcap_variable_urban_rural_choice_3.build_redcap_variable_choice_map(concept_id: @urban_rural_concept_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_urban_rural_choice_3.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_urban_rural_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_urban_rural_choice_3.save!

          @redcap_variable_urban_rural_choice_unmapped = @redcap_variable_urban_rural.redcap_variable_choices.where(choice_description: 'Other').first
          @redcap_variable_urban_rural_choice_unmapped.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_urban_rural_choice_unmapped.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_urban_rural_choice_unmapped.save!

          redcap_variable_choice = @redcap_variable_urban_rural.redcap_variable_choices.where(choice_description: 'Unknown').first
          redcap_variable_choice.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          redcap_variable_choice.save!

          #blood_type
          @redcap_variable_blood_type = Redcap2omop::RedcapVariable.where(name: 'blood_type', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @redcap_variable_blood_type.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          @redcap_variable_blood_type.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @redcap_variable_blood_type.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'condition_occurrence' AND redcap2omop_omop_columns.name = 'condition_start_date'").first

          @redcap_variable_blood_type_choice_1 = @redcap_variable_blood_type.redcap_variable_choices.where(choice_description: 'A').first
          @blood_type_concept_1 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '112144000').first
          @redcap_variable_blood_type_choice_1.build_redcap_variable_choice_map(concept_id: @blood_type_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_blood_type_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_blood_type_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_blood_type_choice_1.save!

          @redcap_variable_blood_type_choice_2 = @redcap_variable_blood_type.redcap_variable_choices.where(choice_description: 'AB').first
          @blood_type_concept_2 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '165743006').first
          @redcap_variable_blood_type_choice_2.build_redcap_variable_choice_map(concept_id: @blood_type_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_blood_type_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_blood_type_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_blood_type_choice_2.save!

          @redcap_variable_blood_type_choice_3 = @redcap_variable_blood_type.redcap_variable_choices.where(choice_description: 'B').first
          @blood_type_concept_3 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '112149005').first
          @redcap_variable_blood_type_choice_3.build_redcap_variable_choice_map(concept_id: @blood_type_concept_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_blood_type_choice_3.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_blood_type_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_blood_type_choice_3.save!

          @redcap_variable_blood_type_choice_4 = @redcap_variable_blood_type.redcap_variable_choices.where(choice_description: 'O').first
          @blood_type_concept_4 = Redcap2omop::Concept.where(domain_id: 'Condition', vocabulary_id: 'SNOMED', concept_code: '58460004').first
          @redcap_variable_blood_type_choice_4.build_redcap_variable_choice_map(concept_id: @blood_type_concept_4.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_blood_type_choice_4.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_blood_type_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_blood_type_choice_4.save!

          @redcap_variable_blood_type_choice_unmapped = @redcap_variable_blood_type.redcap_variable_choices.where(choice_description: 'Unknown').first
          @redcap_variable_blood_type_choice_unmapped.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_blood_type_choice_unmapped.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_blood_type_choice_unmapped.save!

          #o2_requirement
          @redcap_variable_o2_requirement = Redcap2omop::RedcapVariable.where(name: 'o2_requirement', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @redcap_variable_o2_requirement.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          @redcap_variable_o2_requirement.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @redcap_variable_o2_requirement.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'procedure_occurrence' AND redcap2omop_omop_columns.name = 'procedure_date'").first

          @redcap_variable_o2_requirement_choice_1 = @redcap_variable_o2_requirement.redcap_variable_choices.where(choice_description: 'Yes, patient requires chronic supplemental O2').first
          @o2_requirement_concept_1 = Redcap2omop::Concept.where(domain_id: 'Procedure', vocabulary_id: 'SNOMED', concept_code: '57485005').first
          @redcap_variable_o2_requirement_choice_1.build_redcap_variable_choice_map(concept_id: @o2_requirement_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_o2_requirement_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_o2_requirement_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_o2_requirement_choice_1.save!

          @redcap_variable_o2_requirement_choice_2 = @redcap_variable_o2_requirement.redcap_variable_choices.where(choice_description: 'No, patient does not require supplemental O2').first
          @redcap_variable_o2_requirement_choice_2.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_o2_requirement_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_o2_requirement_choice_2.save!

          @redcap_variable_o2_requirement_choice_unmapped = @redcap_variable_o2_requirement.redcap_variable_choices.where(choice_description: 'Unknown').first
          @redcap_variable_o2_requirement_choice_unmapped.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_o2_requirement_choice_unmapped.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_o2_requirement_choice_unmapped.save!

          #hosp_status
          @redcap_variable_hosp_status = Redcap2omop::RedcapVariable.where(name: 'hosp_status', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @redcap_variable_hosp_status.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          @redcap_variable_hosp_status.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @redcap_variable_hosp_status.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_start_date'").first
          omop_column_2 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'visit_occurrence' AND redcap2omop_omop_columns.name = 'visit_end_date'").first

          @redcap_variable_hosp_status_choice_1 = @redcap_variable_hosp_status.redcap_variable_choices.where(choice_description: 'Yes - admitted directly to the ICU').first
          @hosp_status_concept_1 = Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first
          @redcap_variable_hosp_status_choice_1.build_redcap_variable_choice_map(concept_id: @hosp_status_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_hosp_status_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_hosp_status_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_hosp_status_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_hosp_status_choice_1.save!

          @redcap_variable_hosp_status_choice_2 = @redcap_variable_hosp_status.redcap_variable_choices.where(choice_description: 'Yes - admitted to floor').first
          @hosp_status_concept_2 = Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'IP').first
          @redcap_variable_hosp_status_choice_2.build_redcap_variable_choice_map(concept_id: @hosp_status_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_hosp_status_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_hosp_status_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_hosp_status_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_hosp_status_choice_2.save!

          @redcap_variable_hosp_status_choice_3 = @redcap_variable_hosp_status.redcap_variable_choices.where(choice_description: 'Yes - admitted to floor and then transferred to the ICU').first
          @hosp_status_concept_3 = Redcap2omop::Concept.where(domain_id: 'Visit', vocabulary_id: 'Visit', concept_code: 'OMOP4822460').first
          @redcap_variable_hosp_status_choice_3.build_redcap_variable_choice_map(concept_id: @hosp_status_concept_3.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_hosp_status_choice_3.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_hosp_status_choice_3.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_2, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_hosp_status_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_hosp_status_choice_3.save!

          @redcap_variable_hosp_status_choice_4 = @redcap_variable_hosp_status.redcap_variable_choices.where(choice_description: "No").first
          @redcap_variable_hosp_status_choice_4.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_hosp_status_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_hosp_status_choice_4.save!

          @redcap_variable_hosp_status_choice_5 = @redcap_variable_hosp_status.redcap_variable_choices.where(choice_description: "Unknown").first
          @redcap_variable_hosp_status_choice_5.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_hosp_status_choice_5.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_hosp_status_choice_5.save!

          #dic_treatment
          @redcap_variable_dic_treatment = Redcap2omop::RedcapVariable.where(name: 'dic_treatment', redcap_data_dictionary_id: redcap_data_dictionary.id).first
          @redcap_variable_dic_treatment.build_redcap_variable_map(map_type: Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE)
          @redcap_variable_dic_treatment.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
          @redcap_variable_dic_treatment.save!

          omop_column_1 = Redcap2omop::OmopColumn.joins(:omop_table).where("redcap2omop_omop_tables.name = 'device_exposure' AND redcap2omop_omop_columns.name = 'device_exposure_start_date'").first

          @redcap_variable_dic_treatment_choice_1 = @redcap_variable_dic_treatment.redcap_variable_choices.where(choice_description: 'Cryoprecipitate').first
          @dic_treatment_concept_1 = Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '256401009').first
          @redcap_variable_dic_treatment_choice_1.build_redcap_variable_choice_map(concept_id: @dic_treatment_concept_1.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_dic_treatment_choice_1.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_dic_treatment_choice_1.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_dic_treatment_choice_1.save!

          @redcap_variable_dic_treatment_choice_2 = @redcap_variable_dic_treatment.redcap_variable_choices.where(choice_description: 'Plasma (FFP)').first
          @dic_treatment_concept_2 = Redcap2omop::Concept.where(domain_id: 'Device', vocabulary_id: 'SNOMED', concept_code: '346447007').first
          @redcap_variable_dic_treatment_choice_2.build_redcap_variable_choice_map(concept_id: @dic_treatment_concept_2.concept_id, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_dic_treatment_choice_2.redcap_variable_child_maps.build(redcap_variable: other_redcap_variable, omop_column: omop_column_1, map_type: Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE)
          @redcap_variable_dic_treatment_choice_2.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_dic_treatment_choice_2.save!

          @redcap_variable_dic_treatment_choice_3 = @redcap_variable_dic_treatment.redcap_variable_choices.where(choice_description: 'None').first
          @redcap_variable_dic_treatment_choice_3.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_dic_treatment_choice_3.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_dic_treatment_choice_3.save!

          @redcap_variable_dic_treatment_choice_4 = @redcap_variable_dic_treatment.redcap_variable_choices.where(choice_description: 'Other').first
          @redcap_variable_dic_treatment_choice_4.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_dic_treatment_choice_4.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_dic_treatment_choice_4.save!

          @redcap_variable_dic_treatment_choice_5 = @redcap_variable_dic_treatment.redcap_variable_choices.where(choice_description: 'Unknown').first
          @redcap_variable_dic_treatment_choice_5.build_redcap_variable_choice_map(concept_id: 0, map_type: Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
          @redcap_variable_dic_treatment_choice_5.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED
          @redcap_variable_dic_treatment_choice_5.save!



          @record_id_1 = 'abc123'
          @record_id_2 = 'abc456'
          @record_id_3 = 'abc789'
          @screening_d_1 = '2021-03-30'
          @screening_d_2 = '2021-04-30'
          @screening_d_3 = '2021-05-30'
  records = <<-RECORDS
  [
    {
      "record_id": "#{@record_id_1}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "dx_year": "2020",
      "screending_d": "#{@screening_d_1}",
      "urban_rural": "#{@redcap_variable_urban_rural_choice_1.choice_code_raw}",
      "blood_type": "#{@redcap_variable_blood_type_choice_2.choice_code_raw}",
      "o2_requirement": "#{@redcap_variable_o2_requirement_choice_1.choice_code_raw}",
      "hosp_status": "#{@redcap_variable_hosp_status_choice_1.choice_code_raw}",
      "dic_treatment": "#{@redcap_variable_dic_treatment_choice_1.choice_code_raw}",
      "screening_form_complete": "2",
      "first_name": "Firas",
      "last_name": "Wehbe",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    },
    {
      "record_id": "#{@record_id_2}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "dx_year": "2020",
      "screending_d": "#{@screening_d_2}",
      "urban_rural": "#{@redcap_variable_urban_rural_choice_2.choice_code_raw}",
      "blood_type": "#{@redcap_variable_blood_type_choice_4.choice_code_raw}",
      "o2_requirement": "#{@redcap_variable_o2_requirement_choice_unmapped.choice_code_raw}",
      "hosp_status": "#{@redcap_variable_hosp_status_choice_3.choice_code_raw}",
      "dic_treatment": "#{@redcap_variable_dic_treatment_choice_2.choice_code_raw}",
      "screening_form_complete": "2",
      "first_name": "Bob",
      "last_name": "Jones",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    },
    {
      "record_id": "#{@record_id_3}",
      "redcap_event_name": "baseline_arm_1",
      "redcap_repeat_instrument": "",
      "redcap_repeat_instance": "",
      "dx_year": "2020",
      "screending_d": "#{@screening_d_3}",
      "urban_rural": "#{@redcap_variable_blood_type_choice_unmapped.choice_code_raw}",
      "blood_type": "#{@redcap_variable_blood_type_choice_unmapped.choice_code_raw}",
      "o2_requirement": "#{@redcap_variable_o2_requirement_choice_2.choice_code_raw}",
      "hosp_status": "#{@redcap_variable_hosp_status_choice_4.choice_code_raw}",
      "dic_treatment": "#{@redcap_variable_dic_treatment_choice_4.choice_code_raw}",
      "screening_form_complete": "2",
      "first_name": "Bob",
      "last_name": "Jones",
      "dob": "1976-10-14",
      "gender": "3",
      "race___1": "0",
      "race___2": "1",
      "race___3": "0",
      "race___4": "0",
      "race___5": "0",
      "race___6": "1",
      "race___99": "0",
      "ethnicity": "2",
      "hcw": "1",
      "smoking_product___722495000": "0",
      "smoking_product___unk": "0",
      "smoking_product___oth": "0",
      "smoking_product___722496004": "1",
      "smoking_product___722498003": "0",
      "smoking_product___722497008": "1",
      "demographics_complete": "2",
      "v_d": "2020-10-23",
      "v_coordinator": "Michaela",
      "visit_information_complete": "2",
      "moca": "87",
      "mood": "100",
      "test_calc": "187",
      "clock_position_of_wound": "1",
      "visit_data_complete": "0",
      "m_d": "2020-10-23",
      "mri_coordinator": "Jayashri",
      "mri_information_complete": "0"
    }

  ]
  RECORDS
          setup_specs(records)
          expect(Redcap2omop::ConditionOccurrence.count).to eq 0
          expect(Redcap2omop::Observation.count).to eq 0
          expect(Redcap2omop::ProcedureOccurrence.count).to eq 0
          expect(Redcap2omop::VisitOccurrence.count).to eq 0
          service.run
        end

        it "'ConditionOccurrence'", focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_1.person_id).count).to eq 1
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_1.person_id).first.concept.concept_id).to eq @blood_type_concept_2.concept_id
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_1.person_id).first.condition_start_date).to eq Date.parse(@screening_d_1)

          person_2 = Redcap2omop::Person.where(person_source_value: @record_id_2).first
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_2.person_id).count).to eq 1
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_2.person_id).first.concept.concept_id).to eq @blood_type_concept_4.concept_id
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_2.person_id).first.condition_start_date).to eq Date.parse(@screening_d_2)

          person_3  = Redcap2omop::Person.where(person_source_value: @record_id_3).first
          expect(Redcap2omop::ConditionOccurrence.where(person_id: person_3.person_id).count).to eq 0
        end

        it "'DeviceExposure'", focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::DeviceExposure.where(person_id: person_1.person_id).count).to eq 1
          expect(Redcap2omop::DeviceExposure.where(person_id: person_1.person_id).first.concept.concept_id).to eq @dic_treatment_concept_1.concept_id
          expect(Redcap2omop::DeviceExposure.where(person_id: person_1.person_id).first.device_exposure_start_date).to eq Date.parse(@screening_d_1)

          person_2 = Redcap2omop::Person.where(person_source_value: @record_id_2).first
          expect(Redcap2omop::DeviceExposure.where(person_id: person_2.person_id).count).to eq 1
          expect(Redcap2omop::DeviceExposure.where(person_id: person_2.person_id).first.concept.concept_id).to eq @dic_treatment_concept_2.concept_id
          expect(Redcap2omop::DeviceExposure.where(person_id: person_2.person_id).first.device_exposure_start_date).to eq Date.parse(@screening_d_2)

          person_3  = Redcap2omop::Person.where(person_source_value: @record_id_3).first
          expect(Redcap2omop::DeviceExposure.where(person_id: person_3.person_id).count).to eq 0
        end

        it "'Observation'", focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::Observation.where(person_id: person_1.person_id).count).to eq 1
          expect(Redcap2omop::Observation.where(person_id: person_1.person_id).first.concept.concept_id).to eq @urban_rural_concept_1.concept_id
          expect(Redcap2omop::Observation.where(person_id: person_1.person_id).first.observation_date).to eq Date.parse(@screening_d_1)

          person_2 = Redcap2omop::Person.where(person_source_value: @record_id_2).first
          expect(Redcap2omop::Observation.where(person_id: person_2.person_id).count).to eq 1
          expect(Redcap2omop::Observation.where(person_id: person_2.person_id).first.concept.concept_id).to eq @urban_rural_concept_2.concept_id
          expect(Redcap2omop::Observation.where(person_id: person_2.person_id).first.observation_date).to eq Date.parse(@screening_d_2)

          person_3  = Redcap2omop::Person.where(person_source_value: @record_id_3).first
          expect(Redcap2omop::Observation.where(person_id: person_3.person_id).count).to eq 0
        end

        it "'ProcedureOccurrence'", focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::ProcedureOccurrence.where(person_id: person_1.person_id).count).to eq 1
          expect(Redcap2omop::ProcedureOccurrence.where(person_id: person_1.person_id).first.concept.concept_id).to eq @o2_requirement_concept_1.concept_id
          expect(Redcap2omop::ProcedureOccurrence.where(person_id: person_1.person_id).first.procedure_date).to eq Date.parse(@screening_d_1)

          person_2 = Redcap2omop::Person.where(person_source_value: @record_id_2).first
          expect(Redcap2omop::ProcedureOccurrence.where(person_id: person_2.person_id).count).to eq 0

          person_3  = Redcap2omop::Person.where(person_source_value: @record_id_3).first
          expect(Redcap2omop::ProcedureOccurrence.where(person_id: person_3.person_id).count).to eq 0
        end

        it "'VisitOccurrence'", focus: false do
          person_1 = Redcap2omop::Person.where(person_source_value: @record_id_1).first
          expect(Redcap2omop::VisitOccurrence.where(person_id: person_1.person_id).count).to eq 1
          expect(Redcap2omop::VisitOccurrence.where(person_id: person_1.person_id).first.concept.concept_id).to eq @hosp_status_concept_1.concept_id
          expect(Redcap2omop::VisitOccurrence.where(person_id: person_1.person_id).first.visit_start_date).to eq Date.parse(@screening_d_1)
          expect(Redcap2omop::VisitOccurrence.where(person_id: person_1.person_id).first.visit_end_date).to eq Date.parse(@screening_d_1)

          person_2 = Redcap2omop::Person.where(person_source_value: @record_id_2).first
          expect(Redcap2omop::VisitOccurrence.where(person_id: person_2.person_id).count).to eq 1
          expect(Redcap2omop::VisitOccurrence.where(person_id: person_2.person_id).first.concept.concept_id).to eq @hosp_status_concept_3.concept_id
          expect(Redcap2omop::VisitOccurrence.where(person_id: person_2.person_id).first.visit_start_date).to eq Date.parse(@screening_d_2)
          expect(Redcap2omop::VisitOccurrence.where(person_id: person_2.person_id).first.visit_end_date).to eq Date.parse(@screening_d_2)

          person_3  = Redcap2omop::Person.where(person_source_value: @record_id_3).first
          expect(Redcap2omop::VisitOccurrence.where(person_id: person_3.person_id).count).to eq 0
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

  def setup_specs(records)
    stub_redcap_api_record_request(body: records)
    Redcap2omop::DataServices::RedcapImport.new(redcap_project: project).run
  end
end