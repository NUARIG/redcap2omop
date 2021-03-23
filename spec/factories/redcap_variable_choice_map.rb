FactoryBot.define do
  factory :redcap_variable_choice_map, class: 'Redcap2omop::RedcapVariableChoiceMap' do
    association :redcap_variable_choice, factory: :redcap_variable_choice
    map_type { Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPES.sample }
  end
end
