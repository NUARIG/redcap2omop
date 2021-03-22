FactoryBot.define do
  factory :measurement, class: 'Redcap2omop::Measurement' do
    association :person
    association :concept
    association :type_concept, factory: :concept
    measurement_date { Date.today - 1.year}
  end
end
