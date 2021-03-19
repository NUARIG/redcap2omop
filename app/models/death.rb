class Death < ApplicationRecord
  cattr_reader :map_types

  self.table_name = 'death'
  self.primary_key = 'person_id'
  @@map_types = {
    person_id: 'record_id',
    death_date: 'date redcap variable',
    death_datetime: 'skip',
    death_type_concept_id: 'choice redcap variable',
    cause_concept_id: 'choice redcap variable',
    cause_source_value: 'skip',
    cause_source_concept_id: 'skip',
  }
end
