require 'rails_helper'
require 'support/shared_examples/with_next_id'
# RSpec.describe Redcap2omop::Concept, type: :model do
#   describe 'methods' do
#     include_examples 'with next_id'
#
#     it 'returns standard concepts' do
#       concept_1 = FactoryBot.create(:concept, standard_concept: '')
#       concept_2 = FactoryBot.create(:concept, standard_concept: 'S')
#       expect(Redcap2omop::Concept.standard).to match_array([concept_2])
#     end
#
#     it 'returns valid concepts' do
#       concept_1 = FactoryBot.create(:concept, invalid_reason: nil)
#       concept_2 = FactoryBot.create(:concept, invalid_reason: 'U')
#       expect(Redcap2omop::Concept.valid).to match_array([concept_1])
#     end
#
#     it 'returns condition types' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_CONDITION_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_CONDITION_TYPE)
#       concept_2 = FactoryBot.create(:concept,
#                                     invalid_reason:   'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_CONDITION_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_CONDITION_TYPE)
#       concept_3 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_METADATA,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_CONDITION_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_CONDITION_TYPE)
#       expect(Redcap2omop::Concept.condition_types).to match_array([concept_1])
#     end
#
#     it 'returns domain concepts' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_METADATA,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DOMAIN,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_DOMAIN)
#       concept_2 = FactoryBot.create(:concept,
#                                     invalid_reason:   'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_METADATA,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DOMAIN,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_DOMAIN)
#       concept_3 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DOMAIN,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_DOMAIN)
#       expect(Redcap2omop::Concept.domain_concepts).to match_array([concept_1])
#     end
#
#     it 'returns death types' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DEATH_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_DEATH_TYPE)
#       concept_2 = FactoryBot.create(:concept, invalid_reason: 'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DEATH_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_DEATH_TYPE)
#       concept_3 = FactoryBot.create(:concept, invalid_reason: nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DEATH_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_DRUG_TYPE)
#       expect(Redcap2omop::Concept.death_types).to match_array([concept_1])
#     end
#
#     it 'returns drug types' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DRUG_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_DRUG_TYPE)
#       concept_2 = FactoryBot.create(:concept,
#                                     invalid_reason:   'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DRUG_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_DRUG_TYPE)
#       concept_3 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DRUG_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_MEAS_TYPE)
#       expect(Redcap2omop::Concept.drug_types).to match_array([concept_1])
#     end
#
#     it 'returns measurement types' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_MEAS_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_MEAS_TYPE)
#       concept_2 = FactoryBot.create(:concept,
#                                     invalid_reason:   'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_MEAS_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_MEAS_TYPE)
#       concept_3 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_MEAS_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_NOTE_TYPE)
#       expect(Redcap2omop::Concept.measurement_types).to match_array([concept_1])
#     end
#
#     it 'returns note types' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_NOTE_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_NOTE_TYPE)
#       concept_2 = FactoryBot.create(:concept,
#                                     invalid_reason:   'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_NOTE_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_NOTE_TYPE)
#       concept_3 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_NOTE_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_OBSERVATION_TYPE)
#       expect(Redcap2omop::Concept.note_types).to match_array([concept_1])
#     end
#
#     it 'returns observation types' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_OBSERVATION_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_OBSERVATION_TYPE)
#       concept_2 = FactoryBot.create(:concept, invalid_reason: 'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_OBSERVATION_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_OBSERVATION_TYPE)
#       concept_3 = FactoryBot.create(:concept, invalid_reason: nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_NOTE_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_PROCEDURE_TYPE)
#       expect(Redcap2omop::Concept.observation_types).to match_array([concept_1])
#     end
#
#     it 'returns procedure types' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_PROCEDURE_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_PROCEDURE_TYPE)
#       concept_2 = FactoryBot.create(:concept, invalid_reason: 'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_PROCEDURE_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_PROCEDURE_TYPE)
#       concept_3 = FactoryBot.create(:concept, invalid_reason: nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_PROCEDURE_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_QUALIFIER_VALUE)
#       expect(Redcap2omop::Concept.procedure_types).to match_array([concept_1])
#     end
#
#     it 'returns routes' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_ROUTE,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_SNOMED,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_QUALIFIER_VALUE)
#       concept_2 = FactoryBot.create(:concept,
#                                     invalid_reason: 'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_ROUTE,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_SNOMED,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_QUALIFIER_VALUE)
#       concept_3 = FactoryBot.create(:concept,
#                                     invalid_reason: nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_ROUTE,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_SNOMED,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_UNIT)
#       expect(Redcap2omop::Concept.routes).to match_array([concept_1])
#     end
#
#     it 'returns units' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_UNIT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_UCUM,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_UNIT)
#       concept_2 = FactoryBot.create(:concept, invalid_reason: 'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_UNIT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_UCUM,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_UNIT)
#       concept_3 = FactoryBot.create(:concept, invalid_reason: nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_UNIT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_UCUM,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_GENDER)
#       expect(Redcap2omop::Concept.units).to match_array([concept_1])
#     end
#
#     it 'returns genders' do
#       concept_1 = FactoryBot.create(:concept,
#                                     standard:         'S',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_GENDER,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_GENDER,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_GENDER)
#       concept_2 = FactoryBot.create(:concept,
#                                     standard:         'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_GENDER,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_GENDER,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_GENDER)
#       concept_3 = FactoryBot.create(:concept,
#                                     standard:         'S',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_GENDER,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_GENDER,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_RACE)
#       expect(Redcap2omop::Concept.genders).to match_array([concept_1])
#     end
#
#     it 'returns races' do
#       concept_1 = FactoryBot.create(:concept,
#                                     standard:         'S',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_RACE,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_RACE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_RACE)
#       concept_2 = FactoryBot.create(:concept,
#                                     standard:         'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_RACE,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_RACE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_RACE)
#       concept_3 = FactoryBot.create(:concept,
#                                     standard:         'S',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_RACE,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_RACE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_ETHNICITY)
#       expect(Redcap2omop::Concept.races).to match_array([concept_1])
#     end
#
#     it 'returns ethnicities' do
#       concept_1 = FactoryBot.create(:concept,
#                                     standard:         'S',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_ETHNICITY,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_ETHNICITY ,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_ETHNICITY)
#       concept_2 = FactoryBot.create(:concept,
#                                     standard:         'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_ETHNICITY,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_ETHNICITY ,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_ETHNICITY)
#       concept_3 = FactoryBot.create(:concept,
#                                     standard:         'S',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_ETHNICITY,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_ETHNICITY ,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_RACE)
#       expect(Redcap2omop::Concept.ethnicities).to match_array([concept_1])
#     end
#
#     it 'returns procedure concepts' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason: nil,
#                                     domain_id:      Redcap2omop::Concept::DOMAIN_ID_PROCEDURE)
#       concept_2 = FactoryBot.create(:concept,
#                                     invalid_reason: 'U',
#                                     domain_id:      Redcap2omop::Concept::DOMAIN_ID_PROCEDURE)
#       concept_3 = FactoryBot.create(:concept,
#                                     invalid_reason: nil,
#                                     domain_id:      Redcap2omop::Concept::DOMAIN_ID_ROUTE)
#       expect(Redcap2omop::Concept.procedure_concepts).to match_array([concept_1])
#     end
#
#     it 'returns specimen concepts' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason: nil,
#                                     domain_id:      Redcap2omop::Concept::DOMAIN_ID_SPECIMEN)
#       concept_2 = FactoryBot.create(:concept,
#                                     invalid_reason: 'outdated',
#                                     domain_id:      Redcap2omop::Concept::DOMAIN_ID_SPECIMEN)
#       concept_3 = FactoryBot.create(:concept,
#                                     invalid_reason: nil,
#                                     domain_id:      Redcap2omop::Concept::DOMAIN_ID_ROUTE)
#       expect(Redcap2omop::Concept.specimen_concepts).to match_array([concept_1])
#     end
#
#     it 'returns specimen_types' do
#       concept_1 = FactoryBot.create(:concept,
#                                     invalid_reason:   nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_SPECIMEN_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_SPECIMEN_TYPE)
#       concept_2 = FactoryBot.create(:concept, invalid_reason: 'U',
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_SPECIMEN_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_SPECIMEN_TYPE)
#       concept_3 = FactoryBot.create(:concept, invalid_reason: nil,
#                                     domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
#                                     vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_SPECIMEN_TYPE,
#                                     concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_GENDER)
#       expect(Redcap2omop::Concept.specimen_types).to match_array([concept_1])
#     end
#   end
# end
