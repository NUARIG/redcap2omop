require 'rails_helper'
module Redcap2omop
  RSpec.describe RedcapVariableChoiceMap, type: :model do
    let(:redcap_variable_choice_map) { FactoryBot.create(:redcap_variable_choice_map) }
    let(:subject)                    { redcap_variable_choice_map }

    describe 'associations' do
      it { is_expected.to belong_to(:redcap_variable_choice) }
    end
  end
end
