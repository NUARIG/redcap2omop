require 'rails_helper'

module Redcap2omop
  RSpec.describe RedcapDerivedDate, type: :model do
    let(:redcap_derived_date) { FactoryBot.create(:redcap_derived_date) }
    let(:subject)             { redcap_derived_date }

    describe 'associations' do
      it { is_expected.to have_many(:redcap_derived_date_choice_offset_mappings) }
      it { is_expected.to belong_to(:offset_redcap_variable) }
      it { is_expected.to belong_to(:base_date_redcap_variable).optional }
      it { is_expected.to belong_to(:parent_redcap_derived_date).optional }
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:offset_redcap_variable_id) }
      it { is_expected.to validate_uniqueness_of(:name).scoped_to(:redcap_data_dictionary_id) }
    end
  end
end

