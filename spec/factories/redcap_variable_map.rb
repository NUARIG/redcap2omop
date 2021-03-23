FactoryBot.define do
  factory :redcap_variable_map, class: 'Redcap2omop::RedcapVariableMap' do
    association :redcap_variable, factory: :redcap_variable
    map_type { Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPES.sample }
  end
end
