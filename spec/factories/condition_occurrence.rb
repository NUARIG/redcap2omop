FactoryBot.define do
  factory :condition_occurrence, class: 'Redcap2omop::ConditionOccurrence' do
    association :person
    association :concept
    association :type_concept, factory: :concept
    condition_start_date { Date.today - 1.year}
  end
end
