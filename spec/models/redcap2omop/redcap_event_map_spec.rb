require 'rails_helper'
require 'support/shared_examples/with_soft_delete'
module Redcap2omop
  RSpec.describe RedcapEventMap, type: :model do
    let(:redcap_event_map) { FactoryBot.create(:redcap_event_map) }
    let(:subject)          { redcap_event_map }

    describe 'associations' do
      it { is_expected.to belong_to(:redcap_event) }
      it { is_expected.to have_many(:redcap_event_map_dependents) }
      it { is_expected.to belong_to(:omop_column).optional }
      it { is_expected.to belong_to(:concept).optional }
    end

    include_examples 'with soft_delete'
  end
end
