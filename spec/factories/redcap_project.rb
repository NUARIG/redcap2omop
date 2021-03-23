FactoryBot.define do
  factory :redcap_project, class: 'Redcap2omop::RedcapProject' do
    project_id { rand(100) }
    name { Faker::Lorem.word }
  end
end
