FactoryBot.define do
  factory :death, class: 'Redcap2omop::Death' do
    association :person
    association :type_concept, factory: :concept
    death_date { Date.today - 1.year}
  end
end
