require 'rails_helper'
module Redcap2omop
  RSpec.describe RedcapSourceLink, type: :model do
    let(:redcap_source_link) { FactoryBot.create(:redcap_source_link, redcap_source: FactoryBot.create(:redcap_variable), redcap_sourced: FactoryBot.create(:observation)) }
    let(:subject)            { redcap_source_link }

    describe 'associations' do
      it { is_expected.to belong_to(:redcap_source) }
      it { is_expected.to belong_to(:redcap_sourced) }
    end
  end
end
