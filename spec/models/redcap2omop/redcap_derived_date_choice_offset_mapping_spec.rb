require 'rails_helper'

module Redcap2omop
  RSpec.describe RedcapDerivedDateChoiceOffsetMapping, type: :model do
    let(:redcap_derived_date_choice_offset_mapping) { FactoryBot.create(:redcap_derived_date_choice_offset_mapping) }
    let(:subject)                                   { redcap_derived_date_choice_offset_mapping }

    describe 'associations' do
      it { is_expected.to belong_to(:redcap_derived_date) }
      it { is_expected.to belong_to(:redcap_variable_choice) }
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of(:offset_days) }
    end
  end
end

