FactoryBot.define do
  factory :redcap_derived_date_choice_offset_mapping, class: 'Redcap2omop::RedcapDerivedDateChoiceOffsetMapping' do
    association :redcap_derived_date
    association :redcap_variable_choice
    offset_days { rand(100) }
  end
end
