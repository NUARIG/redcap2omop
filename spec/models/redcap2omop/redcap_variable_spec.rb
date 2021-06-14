require 'rails_helper'
require 'support/shared_examples/with_soft_delete'
module Redcap2omop
  RSpec.describe RedcapVariable, type: :model do
    let(:redcap_variable) { FactoryBot.create(:redcap_variable) }
    let(:subject)         { redcap_variable }

    describe 'associations' do
      it { is_expected.to belong_to(:redcap_data_dictionary) }
      it { is_expected.to have_many(:redcap_variable_choices) }
      it { is_expected.to have_one(:redcap_variable_map) }
      it { is_expected.to have_many(:redcap_variable_child_maps) }
      it { is_expected.to have_many(:redcap_source_links) }
    end

    include_examples 'with soft_delete'

    describe 'methods' do
      it 'normalizes field type' do
        %w[radio checkbox dropdown].each do |field_type|
          redcap_variable.field_type = field_type
          expect(redcap_variable.normalize_field_type).to eq 'choice'
        end

        redcap_variable.field_type = 'slider'
        expect(redcap_variable.normalize_field_type).to eq 'number'

        redcap_variable.field_type = 'text'
        redcap_variable.text_validation_type = 'date_ymd'
        expect(redcap_variable.normalize_field_type).to eq 'date'

        redcap_variable.text_validation_type = 'integer'
        expect(redcap_variable.normalize_field_type).to eq 'integer'

        redcap_variable.text_validation_type = ''
        expect(redcap_variable.normalize_field_type).to eq 'text'

        redcap_variable.text_validation_type = 'bzzz'
        expect(redcap_variable.normalize_field_type).to eq 'text'

        redcap_variable.field_type = 'bzzz'
        redcap_variable.text_validation_type = ''
        expect(redcap_variable.normalize_field_type).to eq 'bzzz'
      end

      it 'checks if variable is choice' do
        redcap_variable.field_type_normalized = 'choice'
        redcap_variable.field_type_curated = 'integer'
        expect(redcap_variable).not_to be_choice

        redcap_variable.field_type_curated = ''
        expect(redcap_variable).to be_choice
      end

      it 'checks if variable is checkbox' do
        redcap_variable.field_type = 'checkbox'
        redcap_variable.field_type_curated = 'integer'
        expect(redcap_variable.checkbox?).to eq false

        redcap_variable.field_type_curated = ''
        expect(redcap_variable.checkbox?).to eq true

        redcap_variable.field_type = 'text'
        redcap_variable.field_type_curated = 'integer'
        expect(redcap_variable.checkbox?).to eq false
      end

      it 'checks if variable is integer' do
        redcap_variable.field_type_normalized = 'checkbox'
        redcap_variable.field_type_curated = 'integer'
        expect(redcap_variable.integer?).to eq true

        redcap_variable.field_type_normalized = 'text'
        redcap_variable.field_type_curated = 'text'
        expect(redcap_variable.integer?).to eq false
      end

      describe 'mapping redcap variable_choices to concept' do
        it 'allows to map checkbox choices' do
          redcap_variable.field_type = 'checkbox'
          redcap_variable.field_type_curated = nil
          redcap_variable.choices = "1, 1 Yes | 0, 0 No | 99, 99 Unknown"
          redcap_variable.save!
          redcap_variable.reload.redcap_variable_choices.each do |redcap_variable_choice|
            redcap_variable_choice.build_redcap_variable_choice_map(concept_id: FactoryBot.create(:concept).id, map_type: RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
            redcap_variable_choice.save!
          end

          redcap_record = {
            "#{redcap_variable.name}___1" => '1'
          }
          expect(redcap_variable.reload.map_redcap_variable_choice_to_concept(redcap_record)).to eq redcap_variable.redcap_variable_choices.first.redcap_variable_choice_map.concept_id
        end

        it 'allows to map radiobutton choices' do
          redcap_variable.field_type = 'radio'
          redcap_variable.field_type_curated = nil
          redcap_variable.choices = "1, 1 Yes | 0, 0 No | 99, 99 Unknown"
          redcap_variable.save!
          redcap_variable.reload.redcap_variable_choices.each do |redcap_variable_choice|
            redcap_variable_choice.build_redcap_variable_choice_map(concept_id: FactoryBot.create(:concept).id, map_type: RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
            redcap_variable_choice.save!
          end

          redcap_record = {
            "#{redcap_variable.name}" => '1'
          }
          expect(redcap_variable.map_redcap_variable_choice_to_concept(redcap_record)).to eq redcap_variable.redcap_variable_choices.first.redcap_variable_choice_map.concept_id
        end

        it 'allows to map dropdown choices' do
          redcap_variable.field_type = 'radio'
          redcap_variable.field_type_curated = nil
          redcap_variable.choices = "1, 1 Yes | 0, 0 No | 99, 99 Unknown"
          redcap_variable.save!
          redcap_variable.reload.redcap_variable_choices.each do |redcap_variable_choice|
            redcap_variable_choice.build_redcap_variable_choice_map(concept_id: FactoryBot.create(:concept).id, map_type: RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
            redcap_variable_choice.save!
          end

          redcap_record = {
            "#{redcap_variable.name}" => '1'
          }
          expect(redcap_variable.map_redcap_variable_choice_to_concept(redcap_record)).to eq redcap_variable.redcap_variable_choices.first.redcap_variable_choice_map.concept_id
        end

        it 'allows to map integer choices' do
          redcap_variable.field_type = 'dropdown'
          redcap_variable.field_type_normalized = 'integer'
          redcap_variable.choices = "1, 1 Yes | 0, 0 No | 99, 99 Unknown"
          redcap_variable.save!
          redcap_variable.reload.redcap_variable_choices.each do |redcap_variable_choice|
            redcap_variable_choice.build_redcap_variable_choice_map(concept_id: FactoryBot.create(:concept).id, map_type: RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
            redcap_variable_choice.save!
          end

          redcap_record = {
            "#{redcap_variable.name}" => '99'
          }
          expect(redcap_variable.map_redcap_variable_choice_to_concept(redcap_record)).to eq redcap_variable.redcap_variable_choices.last.redcap_variable_choice_map.concept_id
        end
      end

      it 'allows to determine field_type' do
        redcap_variable.field_type_curated = nil
        expect(redcap_variable.determine_field_type).to eq redcap_variable.field_type_normalized
        redcap_variable.field_type_curated = 'integer'
        expect(redcap_variable.determine_field_type).to eq redcap_variable.field_type_curated
      end

      describe 'setting variable_choices' do
        it 'does not set if choices are empty' do
          redcap_variable.choices = ''
          redcap_variable.save!
          expect(redcap_variable.redcap_variable_choices).to be_blank
        end

        it 'sets choices' do
          redcap_variable.choices = "1, 1 Yes | 0, 0 No"
          expect{
            redcap_variable.save!
          }.to change{ Redcap2omop::RedcapVariableChoice.count }.by(2)

          expect(redcap_variable.redcap_variable_choices.first.choice_code_raw).to eq '1'
          expect(redcap_variable.redcap_variable_choices.first.choice_description).to eq '1 Yes'
          expect(redcap_variable.redcap_variable_choices.first.vocabulary_id_raw).to be_nil
          expect(redcap_variable.redcap_variable_choices.first.ordinal_position).to eq 0.0
          expect(redcap_variable.redcap_variable_choices.first.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED

          expect(redcap_variable.redcap_variable_choices.last.choice_code_raw).to eq '0'
          expect(redcap_variable.redcap_variable_choices.last.choice_description).to eq '0 No'
          expect(redcap_variable.redcap_variable_choices.last.vocabulary_id_raw).to be_nil
          expect(redcap_variable.redcap_variable_choices.last.ordinal_position).to eq 1.0
          expect(redcap_variable.redcap_variable_choices.last.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED
        end

        it 'does not set choices again' do
          redcap_variable.choices = "1, 1 Yes | 0, 0 No"
          expect{
            redcap_variable.save!
          }.to change{ Redcap2omop::RedcapVariableChoice.count }

          redcap_variable.choices = "1, 1 Yes | 0, 0 No | 99, 99 Unknown"
          expect{
            redcap_variable.save!
          }.not_to change{ Redcap2omop::RedcapVariableChoice.count }
        end

      end
    end

    describe 'scopes' do
      it 'returns records by name' do
        name = Faker::Lorem.word
        expect(Redcap2omop::RedcapVariable.get_by_name(name)).to be_nil

        redcap_variable
        expect(Redcap2omop::RedcapVariable.get_by_name(name)).to be_nil

        redcap_variable.name = name
        redcap_variable.save!
        expect(Redcap2omop::RedcapVariable.get_by_name(name)).to eq redcap_variable
      end
    end
  end
end
