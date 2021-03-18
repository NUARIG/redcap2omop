FactoryBot.define do
  factory :redcap_event, class: 'Redcap2omop::RedcapEvent' do
    association :redcap_data_dictionary, factory: :redcap_data_dictionary
    event_name { Faker.name }
    arm_num { rand(100) }
    day_offset { 0 }
    offset_min { 0 }
    offset_max { 0 }
    unique_event_name { Faker.name }
  end
end
