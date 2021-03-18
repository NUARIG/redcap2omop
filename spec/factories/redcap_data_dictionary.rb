FactoryBot.define do
  factory :redcap_data_dictionary, class: 'Redcap2omop::RedcapDataDictionary' do
    association :redcap_project, factory: :redcap_project
  end
end
