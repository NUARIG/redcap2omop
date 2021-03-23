FactoryBot.define do
  factory :redcap_variable, class: 'Redcap2omop::RedcapVariable' do
    association :redcap_data_dictionary, factory: :redcap_data_dictionary
    name { Faker.name }
    form_name { Faker.name }
    field_type { Faker.name }
    field_type_normalized { Faker.name }
    field_label { Faker.name }
  end
end

