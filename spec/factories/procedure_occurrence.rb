FactoryBot.define do
  factory :procedure_occurrence, class: 'Redcap2omop::ProcedureOccurrence' do
    association :person
    association :concept
    association :type_concept, factory: :concept
    procedure_date { Date.today - 1.year}
  end
end
