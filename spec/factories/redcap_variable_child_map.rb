FactoryBot.define do
  factory :redcap_variable_child_map, class: 'Redcap2omop::RedcapVariableChildMap' do
    association :redcap_variable, factory: :redcap_variable
    map_type { Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPES.sample }
  end
end
