require 'rails_helper'
module Redcap2omop
  RSpec.describe RedcapVariableMap, type: :model do
    let(:redcap_variable_map) { FactoryBot.create(:redcap_variable_map) }
    let(:subject)             { redcap_variable_map }

    describe 'associations' do
      it { is_expected.to belong_to(:redcap_variable) }
      it { is_expected.to belong_to(:omop_column).optional }
      it { is_expected.to belong_to(:concept).optional }
    end

    describe 'scopes' do
      it 'scopes by omop table' do
        omop_table = FactoryBot.create(:omop_table)
        expect(RedcapVariableMap.by_omop_table(omop_table.name)).to be_empty

        omop_column = FactoryBot.create(:omop_column)
        expect(RedcapVariableMap.by_omop_table(omop_column.omop_table.name)).to be_empty

        redcap_variable_map.omop_column = omop_column
        redcap_variable_map.save!
        expect(RedcapVariableMap.by_omop_table(omop_column.omop_table.name)).to match_array([redcap_variable_map])
      end

      it 'scopes by redcap dictionary' do
        redcap_data_dictionary = FactoryBot.create(:redcap_data_dictionary)
        expect(RedcapVariableMap.by_redcap_dictionary(redcap_data_dictionary)).to be_empty

        redcap_variable = FactoryBot.create(:redcap_variable)
        expect(RedcapVariableMap.by_redcap_dictionary(redcap_variable.redcap_data_dictionary)).to be_empty

        redcap_variable_map.redcap_variable = redcap_variable
        redcap_variable_map.save!
        expect(RedcapVariableMap.by_redcap_dictionary(redcap_variable.redcap_data_dictionary)).to match_array([redcap_variable_map])
      end
    end
  end
end
