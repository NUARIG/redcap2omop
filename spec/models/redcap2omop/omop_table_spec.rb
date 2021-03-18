require 'rails_helper'
require 'support/shared_examples/with_soft_delete'
module Redcap2omop
  RSpec.describe OmopTable, type: :model do
    let(:omop_table) { FactoryBot.create(:omop_table) }
    let(:subject)    { omop_table }

    describe 'associations' do
      it { is_expected.to have_many(:omop_columns) }
      it { is_expected.to accept_nested_attributes_for(:omop_columns) }
    end

    include_examples 'with soft_delete'
  end
end

