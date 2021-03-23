FactoryBot.define do
  factory :redcap_variable_choice, class: 'Redcap2omop::RedcapVariableChoice' do
    association :redcap_variable, factory: :redcap_variable
    choice_code_raw { '1' }
    choice_description { Faker::Lorem.sentence}
    ordinal_position { 1 }
    curation_status { Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUSES.sample }
  end
end
