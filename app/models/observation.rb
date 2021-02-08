class Observation < ApplicationRecord
  include WithNextId
  cattr_reader :map_types

  self.table_name   = 'observation'
  self.primary_key  = 'observation_id'
  @@map_types = {
    observation_id: 'primary key',
    person_id: 'person',
    observation_concept_id: 'domain concept',
    observation_date: 'date redcap variable',
    observation_datetime: 'skip',
    observation_type_concept_id: 'hardcode',
    value_as_number: 'numeric redcap variable',
    value_as_string: 'skip',
    value_as_concept_id: 'choice redcap variable',
    qualifier_concept_id: 'skip',
    unit_concept_id: 'hardcode',
    provider_id: 'provider',
    visit_occurrence_id: 'visit_occurrence',
    visit_detail_id: 'skip',
    observation_source_value: 'redcap variable name',
    observation_source_concept_id: 'skip',
    unit_source_value: 'skip',
    qualifier_source_value: 'skip',
    value_source_value: 'redcap choice'
  }
  DOMAIN_ID = 'Observation'

  has_one :redcap_source_link, as: :redcap_sourced

  def self.domain
    DOMAIN_ID
  end

  def instance_id=(value)
    self.observation_id = value
  end

  def concept_id=(value)
    self.observation_concept_id = value
  end

  def type_concept_id=(value)
    self.observation_type_concept_id = value
  end

  def source_value=(value)
    self.observation_source_value = value
  end
end
