require 'rails_helper'
require 'support/shared_examples/with_next_id'
module Redcap2omop
  RSpec.describe ProcedureOccurrence, type: :model do
    let(:procedure_occurrence)  { FactoryBot.create(:procedure_occurrence) }
    let(:subject)               { procedure_occurrence }

    describe 'associations' do
      it { is_expected.to have_one(:redcap_source_link) }
      it { is_expected.to belong_to(:person) }
      it { is_expected.to belong_to(:provider).optional }
      it { is_expected.to belong_to(:concept) }
      it { is_expected.to belong_to(:type_concept) }
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of(:procedure_date) }
    end

    describe 'methods' do
      it 'allows to set instance_id' do
        new_value = procedure_occurrence.procedure_occurrence_id + 100
        procedure_occurrence.instance_id = new_value
        expect(procedure_occurrence.procedure_occurrence_id).to eq new_value
      end

      it 'allows to set concept_id' do
        new_value = procedure_occurrence.procedure_concept_id + 100
        procedure_occurrence.concept_id = new_value
        expect(procedure_occurrence.procedure_concept_id).to eq new_value
      end

      it 'allows to set type_concept_id' do
        new_value = procedure_occurrence.procedure_type_concept_id + 100
        procedure_occurrence.type_concept_id = new_value
        expect(procedure_occurrence.procedure_type_concept_id).to eq new_value
      end

      it 'allows to set source_value' do
        procedure_occurrence.procedure_source_value = '100'
        new_value = 'hello'
        procedure_occurrence.source_value = new_value
        expect(procedure_occurrence.procedure_source_value).to eq new_value
      end
    end

    include_examples 'with next_id'
  end
end
