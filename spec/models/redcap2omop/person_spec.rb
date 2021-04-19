require 'rails_helper'
require 'support/shared_examples/with_next_id'
module Redcap2omop
  RSpec.describe Person, type: :model do
    let(:person) { FactoryBot.create(:person) }
    let(:subject){ person }

    describe 'associations' do
      it { is_expected.to have_many(:observations) }
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of(:gender_concept_id) }
      it { is_expected.to validate_presence_of(:year_of_birth) }
      it { is_expected.to validate_presence_of(:race_concept_id) }
      it { is_expected.to validate_presence_of(:ethnicity_concept_id) }
    end

    describe 'methods' do
      it 'sets birth fields' do
        person = FactoryBot.build(:person, year_of_birth: nil, month_of_birth: nil, day_of_birth: nil )
        expect(person.year_of_birth).to be_blank
        expect(person.month_of_birth).to be_blank
        expect(person.day_of_birth).to be_blank
        new_datetime = DateTime.now
        person.birth_datetime = new_datetime
        person.set_birth_fields
        expect(person.year_of_birth).to eq(new_datetime.year)
        expect(person.month_of_birth).to eq(new_datetime.month)
        expect(person.day_of_birth).to eq(new_datetime.day)
      end
    end

    include_examples 'with next_id'
  end
end
