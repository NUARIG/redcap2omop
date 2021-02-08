class Measurement < ApplicationRecord
  include WithNextId
  cattr_reader :map_types

  self.table_name = 'measurement'
  self.primary_key = 'measurement_id'
  @@map_types = {
    measurement_id: 'primary key',
    person_id: 'person',
    measurement_concept_id: 'domain concept',
    measurement_date: 'date redcap variable',
    measurement_datetime: 'skip',
    measurement_time: 'skip',
    measurement_type_concept_id: 'hardcode',
    operator_concept_id: 'skip',
    value_as_number: 'numeric redcap variable',
    value_as_concept_id: 'choice redcap variable',
    unit_concept_id: 'skip',
    range_low: 'skip',
    range_high: 'skip',
    provider_id: 'provider',
    visit_occurrence_id: 'visit_occurrence',
    visit_detail_id: 'skip',
    measurement_source_value: 'redcap variable name|choice redcap variable choice description',
    measurement_source_concept_id: 'skip',
    unit_source_value: 'skip',
    value_source_value: 'skip'
  }
  DOMAIN_ID = 'Measurement'

  has_one :redcap_source_link, as: :redcap_sourced

  def self.domain
    DOMAIN_ID
  end

  def instance_id=(value)
    self.measurement_id = value
  end

  def concept_id=(value)
    self.measurement_concept_id = value
  end

  def type_concept_id=(value)
    self.measurement_type_concept_id = value
  end

  def source_value=(value)
    self.measurement_source_value = value
  end
end
