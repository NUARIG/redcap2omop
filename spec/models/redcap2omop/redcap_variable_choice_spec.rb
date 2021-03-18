require 'rails_helper'
require 'support/shared_examples/with_soft_delete'
module Redcap2omop
  RSpec.describe RedcapVariableChoice, type: :model do
    let(:redcap_variable_choice) { FactoryBot.create(:redcap_variable_choice) }
    let(:subject)                { redcap_variable_choice }

    describe 'associations' do
      it { is_expected.to belong_to(:redcap_variable) }
      it { is_expected.to have_one(:redcap_variable_choice_map) }
    end

    include_examples 'with soft_delete'
  end
end
