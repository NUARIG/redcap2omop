class Person < ApplicationRecord
  include WithNextId
  cattr_reader :map_types

  self.table_name = 'person'
  self.primary_key = 'person_id'
  @@map_types = { person_id: 'record_id',
                  gender_concept_id: 'choice redcap variable',
                  year_of_birth: 'date redcap variable year',
                  month_of_birth: 'date redcap variable month',
                  day_of_birth: 'date redcap variable month day',
                  birth_datetime: 'date redcap variable month',
                  race_concept_id: 'choice redcap variable',
                  ethnicity_concept_id: 'choice redcap variable',
                  location_id: 'skip',
                  provider_id: 'skip',
                  care_site_id: 'skip',
                  person_source_value: 'record_id',
                  gender_source_value: 'choice redcap variable choice description',
                  gender_source_concept_id: 'skip',
                  race_source_value: 'choice redcap variable choice description',
                  race_source_concept_id: 'skip',
                  ethnicity_source_value: 'choice redcap variable choice description',
                  ethnicity_source_concept_id: 'skip'
  }

  validates_presence_of :gender_concept_id, :year_of_birth, :race_concept_id, :ethnicity_concept_id

  before_validation :set_birth_fields

  def set_birth_fields
    if self.birth_datetime.present?
      self.year_of_birth  = self.birth_datetime.year
      self.month_of_birth = self.birth_datetime.month
      self.day_of_birth   = self.birth_datetime.day
    end
  end
end
