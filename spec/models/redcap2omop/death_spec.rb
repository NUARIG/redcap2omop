require 'rails_helper'
module Redcap2omop
  RSpec.describe Death, type: :model do
    let(:death)   { FactoryBot.create(:death) }
    let(:subject) { death }

    describe 'associations' do
      it { is_expected.to belong_to(:type_concept) }
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of(:death_date) }
    end
  end
end
