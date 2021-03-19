class ConditionOccurrence < ApplicationRecord
  include WithNextId
  cattr_reader :map_types

  self.table_name = 'condition_occurrence'
  self.primary_key = 'condition_occurrence_id'
  @@map_types = {
    condition_occurrence_id: 'primary key',
    person_id: 'person',
    condition_concept_id: 'domain concept',
    condition_start_date: 'date redcap variable|derived redcap date',
    condition_start_datetime: 'skip',
    condition_end_date: 'date redcap variable|derived redcap date',
    condition_end_datetime: 'skip',
    condition_type_concept_id: 'hardcode',
    stop_reason: 'skip',
    provider_id: 'provider',
    visit_occurrence_id: 'visit_occurrence',
    visit_detail_id: 'skip',
    condition_source_value: 'redcap variable name|choice redcap variable choice description',
    condition_source_concept_id: 'skip',
    condition_status_source_value: 'skip',
    condition_status_concept_id: 'skip'
  }
  DOMAIN_ID = 'Condition'

  has_one :redcap_source_link, as: :redcap_sourced

  def self.domain
    DOMAIN_ID
  end

  def instance_id=(value)
    self.condition_occurrence_id = value
  end

  def concept_id=(value)
    self.condition_concept_id = value
  end

  def type_concept_id=(value)
    self.condition_type_concept_id = value
  end

  def source_value=(value)
    self.condition_source_value = value
  end
end