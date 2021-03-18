FactoryBot.define do
  factory :redcap_variable_child_map, class: 'Redcap2omop::RedcapVariableChildMap' do
    association :redcap_variable, factory: :redcap_variable
  end
end
