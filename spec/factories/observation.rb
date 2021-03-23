FactoryBot.define do
  factory :observation, class: 'Redcap2omop::Observation' do
    association :person
    association :concept
    association :type_concept, factory: :concept
    observation_date { Date.today - 1.year}
  end
end
