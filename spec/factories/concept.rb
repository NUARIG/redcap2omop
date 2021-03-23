FactoryBot.define do
  factory :concept, class: 'Redcap2omop::Concept' do
    concept_name { Faker::Lorem.word }
    domain_id { Redcap2omop::Concept::DOMAIN_IDS.sample }
    vocabulary_id { Redcap2omop::Concept::VOCABULARY_IDS.sample }
    concept_class_id { Redcap2omop::Concept::CONCEPT_CLASSES.sample }
    standard_concept { 'S' }
    concept_code { Faker::Lorem.word }
    valid_start_date {Date.today - 1.year}
    valid_end_date {Date.today + 1.year}
    invalid_reason { ''}
  end
end
