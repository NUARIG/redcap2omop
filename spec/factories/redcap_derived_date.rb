FactoryBot.define do
  factory :redcap_derived_date, class: 'Redcap2omop::RedcapDerivedDate' do
    association :redcap_data_dictionary, factory: :redcap_data_dictionary
    association :offset_redcap_variable, factory: :redcap_variable
    name { Faker.name }
  end
end
