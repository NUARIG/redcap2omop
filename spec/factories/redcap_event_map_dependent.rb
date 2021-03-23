FactoryBot.define do
  factory :redcap_event_map_dependent, class: 'Redcap2omop::RedcapEventMapDependent' do
    association :redcap_variable, factory: :redcap_variable
    association :redcap_event, factory: :redcap_event
    association :redcap_event_map, factory: :redcap_event_map
  end
end
