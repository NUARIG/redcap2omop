FactoryBot.define do
  factory :redcap_event_map, class: 'Redcap2omop::RedcapEventMap' do
    association :redcap_event, factory: :redcap_event
  end
end
