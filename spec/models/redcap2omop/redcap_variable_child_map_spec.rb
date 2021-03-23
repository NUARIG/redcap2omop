require 'rails_helper'
module Redcap2omop
  RSpec.describe RedcapVariableChildMap, type: :model do
    let(:redcap_variable_child_map) { FactoryBot.create(:redcap_variable_child_map, parentable: FactoryBot.create(:redcap_variable)) }
    let(:subject)                   { redcap_variable_child_map }

    describe 'associations' do
      it { is_expected.to belong_to(:redcap_variable).optional }
      it { is_expected.to belong_to(:parentable) }
      it { is_expected.to belong_to(:omop_column).optional }
      it { is_expected.to belong_to(:concept).optional }
    end
  end
end
