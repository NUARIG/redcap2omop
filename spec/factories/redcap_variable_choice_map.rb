FactoryBot.define do
  factory :redcap_variable_choice_map, class: 'Redcap2omop::RedcapVariableChoiceMap' do
    association :redcap_variable_choice, factory: :redcap_variable_choice
  end
end
