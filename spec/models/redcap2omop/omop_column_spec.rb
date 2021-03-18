require 'rails_helper'
require 'support/shared_examples/with_soft_delete'
module Redcap2omop
  RSpec.describe OmopColumn, type: :model do
    let(:omop_column) { FactoryBot.create(:omop_column) }
    let(:subject)     { omop_column }

    describe 'associations' do
      it { is_expected.to belong_to(:omop_table) }
    end

    include_examples 'with soft_delete'
  end
end
