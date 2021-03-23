FactoryBot.define do
  factory :device_exposure, class: 'Redcap2omop::DeviceExposure' do
    association :person
    association :concept
    association :type_concept, factory: :concept
    device_exposure_start_date { Date.today - 1.year}
  end
end
