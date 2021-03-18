FactoryBot.define do
  factory :person, class: 'Redcap2omop::Person' do
    gender_concept_id { rand(1000) }
    year_of_birth { Date.today.year}
    race_concept_id { rand(1000) }
    ethnicity_concept_id { rand(1000) }
  end
end
