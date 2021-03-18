require 'rails_helper'
require 'support/shared_examples/with_soft_delete'
module Redcap2omop
  RSpec.describe RedcapEventMapDependent, type: :model do
    let(:redcap_event_map_dependent) { FactoryBot.create(:redcap_event_map_dependent) }
    let(:subject)     { redcap_event_map_dependent }

    describe 'associations' do
      it { is_expected.to belong_to(:redcap_event) }
      it { is_expected.to belong_to(:redcap_variable) }
      it { is_expected.to belong_to(:redcap_event_map) }
      it { is_expected.to belong_to(:omop_column).optional }
      it { is_expected.to belong_to(:concept).optional }
    end

    include_examples 'with soft_delete'
  end
end
