require 'rails_helper'
require 'support/shared_examples/with_next_id'
module Redcap2omop
  RSpec.describe Measurement, type: :model do
    let(:measurement) { FactoryBot.create(:measurement) }
    let(:subject)     { measurement }

    describe 'associations' do
      it { is_expected.to have_one(:redcap_source_link) }
      it { is_expected.to belong_to(:person) }
      it { is_expected.to belong_to(:provider).optional }
      it { is_expected.to belong_to(:concept) }
      it { is_expected.to belong_to(:type_concept) }
      it { is_expected.to belong_to(:value_as_concept).optional }
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of(:measurement_date) }
    end

    describe 'methods' do
      it 'allows to set instance_id' do
        new_value = measurement.measurement_id + 100
        measurement.instance_id = new_value
        expect(measurement.measurement_id).to eq new_value
      end

      it 'allows to set concept_id' do
        new_value = measurement.measurement_concept_id + 100
        measurement.concept_id = new_value
        expect(measurement.measurement_concept_id).to eq new_value
      end

      it 'allows to set type_concept_id' do
        new_value = measurement.measurement_type_concept_id + 100
        measurement.type_concept_id = new_value
        expect(measurement.measurement_type_concept_id).to eq new_value
      end

      it 'allows to set source_value' do
        measurement.measurement_source_value = '100'
        new_value = 'hello'
        measurement.source_value = new_value
        expect(measurement.measurement_source_value).to eq new_value
      end
    end

    include_examples 'with next_id'
  end
end
