require 'rails_helper'
require 'support/shared_examples/with_next_id'
module Redcap2omop
  RSpec.describe DeviceExposure, type: :model do
    let(:device_exposure) { FactoryBot.create(:device_exposure) }
    let(:subject)         { device_exposure }

    describe 'associations' do
      it { is_expected.to have_one(:redcap_source_link) }
      it { is_expected.to belong_to(:person) }
      it { is_expected.to belong_to(:provider).optional }
      it { is_expected.to belong_to(:concept) }
      it { is_expected.to belong_to(:type_concept) }
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of(:device_exposure_start_date) }
    end

    describe 'methods' do
      it 'allows to set instance_id' do
        new_value = device_exposure.device_exposure_id + 100
        device_exposure.instance_id = new_value
        expect(device_exposure.device_exposure_id).to eq new_value
      end

      it 'allows to set concept_id' do
        new_value = device_exposure.device_concept_id + 100
        device_exposure.concept_id = new_value
        expect(device_exposure.device_concept_id).to eq new_value
      end

      it 'allows to set type_concept_id' do
        new_value = device_exposure.device_type_concept_id + 100
        device_exposure.type_concept_id = new_value
        expect(device_exposure.device_type_concept_id).to eq new_value
      end

      it 'allows to set source_value' do
        device_exposure.device_source_value = '100'
        new_value = 'hello'
        device_exposure.source_value = new_value
        expect(device_exposure.device_source_value).to eq new_value
      end
    end

    include_examples 'with next_id'
  end
end
