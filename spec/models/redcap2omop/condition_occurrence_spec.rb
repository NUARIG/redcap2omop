require 'rails_helper'
require 'support/shared_examples/with_next_id'
module Redcap2omop
  RSpec.describe ConditionOccurrence, type: :model do
    let(:condition_occurrence)  { FactoryBot.create(:condition_occurrence) }
    let(:subject)               { condition_occurrence }

    describe 'associations' do
      it { is_expected.to have_one(:redcap_source_link) }
      it { is_expected.to belong_to(:person) }
      it { is_expected.to belong_to(:provider).optional }
      it { is_expected.to belong_to(:concept) }
      it { is_expected.to belong_to(:type_concept) }
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of(:condition_start_date) }
    end

    describe 'methods' do
      it 'allows to set instance_id' do
        new_value = condition_occurrence.condition_occurrence_id + 100
        condition_occurrence.instance_id = new_value
        expect(condition_occurrence.condition_occurrence_id).to eq new_value
      end

      it 'allows to set concept_id' do
        new_value = condition_occurrence.condition_concept_id + 100
        condition_occurrence.concept_id = new_value
        expect(condition_occurrence.condition_concept_id).to eq new_value
      end

      it 'allows to set type_concept_id' do
        new_value = condition_occurrence.condition_type_concept_id + 100
        condition_occurrence.type_concept_id = new_value
        expect(condition_occurrence.condition_type_concept_id).to eq new_value
      end

      it 'allows to set source_value' do
        condition_occurrence.condition_source_value = '100'
        new_value = 'hello'
        condition_occurrence.source_value = new_value
        expect(condition_occurrence.condition_source_value).to eq new_value
      end
    end

    include_examples 'with next_id'
  end
end
