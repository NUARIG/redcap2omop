class Provider < ApplicationRecord
  include WithNextId
  cattr_reader :map_types

  self.table_name  = 'provider'
  self.primary_key = 'provider_id'
  @@map_types = {
    provider_id: 'primary key',
    provider_name: 'text redcap variable',
    npi: 'text redcap variable',
    dea: 'text redcap variable',
    specialty_concept_id: 'choice redcap variable',
    care_site_id: 'care_site',
    year_of_birth: 'date redcap variable year',
    gender_concept_id: 'choice redcap variable',
    provider_source_value: 'text redcap variable',
    specialty_source_value: 'choice redcap variable choice description',
    specialty_source_concept_id: 'skip',
    gender_source_value: 'choice redcap variable choice description',
    gender_source_concept_id: 'skip'
  }
end
