FactoryBot.define do
  factory :redcap_variable_map, class: 'Redcap2omop::RedcapVariableMap' do
    association :redcap_variable, factory: :redcap_variable
  end
end
