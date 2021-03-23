require 'rails_helper'
require 'support/shared_examples/with_next_id'
module Redcap2omop
  RSpec.describe Observation, type: :model do
    let(:observation) { FactoryBot.create(:observation) }
    let(:subject)     { observation }

    describe 'associations' do
      it { is_expected.to have_one(:redcap_source_link) }
      it { is_expected.to belong_to(:person) }
      it { is_expected.to belong_to(:provider).optional }
      it { is_expected.to belong_to(:concept) }
    end

    describe 'methods' do
      it 'allows to set instance_id' do
        new_value = observation.observation_id + 100
        observation.instance_id = new_value
        expect(observation.observation_id).to eq new_value
      end

      it 'allows to set concept_id' do
        new_value = observation.observation_concept_id + 100
        observation.concept_id = new_value
        expect(observation.observation_concept_id).to eq new_value
      end

      it 'allows to set type_concept_id' do
        new_value = observation.observation_type_concept_id + 100
        observation.type_concept_id = new_value
        expect(observation.observation_type_concept_id).to eq new_value
      end

      it 'allows to set source_value' do
        observation.observation_source_value = '100'
        new_value = 'hello'
        observation.source_value = new_value
        expect(observation.observation_source_value).to eq new_value
      end
    end

    include_examples 'with next_id'
  end
end
