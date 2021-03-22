FactoryBot.define do
  factory :redcap_derived_date, class: 'Redcap2omop::RedcapDerivedDate' do
    association :offset_redcap_variable, factory: :redcap_variable
    name { Faker.name }
  end
end
