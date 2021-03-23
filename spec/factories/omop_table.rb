FactoryBot.define do
  factory :omop_table, class: 'Redcap2omop::OmopTable' do
    name { Faker::Lorem.word }
  end
end
