require 'rails_helper'
require 'support/shared_examples/with_soft_delete'
module Redcap2omop
  RSpec.describe RedcapEvent, type: :model do
    let(:redcap_event) { FactoryBot.create(:redcap_event) }
    let(:subject)          { redcap_event }

    describe 'associations' do
      it { is_expected.to belong_to(:redcap_data_dictionary) }
      it { is_expected.to have_many(:redcap_event_maps) }
    end

    include_examples 'with soft_delete'
  end
end
