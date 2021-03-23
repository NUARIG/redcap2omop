FactoryBot.define do
  factory :omop_column, class: 'Redcap2omop::OmopColumn' do
    association :omop_table, factory: :omop_table
    name { Faker::Lorem.word }
    data_type { 'integer' }
    map_type { 'skip' }
  end
end
