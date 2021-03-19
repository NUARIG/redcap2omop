class ProcedureOccurrence < ApplicationRecord
  include WithNextId
  cattr_reader :map_types

  self.table_name = 'procedure_occurrence'
  self.primary_key = 'procedure_occurrence_id'
  @@map_types = {
    procedure_occurrence_id: 'primary key',
    person_id: 'person',
    procedure_concept_id: 'domain concept',
    procedure_date: 'date redcap variable|derived redcap date',
    procedure_datetime: 'skip',
    procedure_type_concept_id: 'hardcode',
    modifier_concept_id: 'skip',
    quantity: 'skip',
    provider_id: 'provider',
    visit_occurrence_id: 'visit_occurrence',
    visit_detail_id: 'skip',
    procedure_source_value: 'redcap variable name|choice redcap variable choice description',
    procedure_source_concept_id: 'skip',
    modifier_source_value: 'skip'
  }
  DOMAIN_ID = 'Procedure'

  has_one :redcap_source_link, as: :redcap_sourced

  def self.domain
    DOMAIN_ID
  end

  def instance_id=(value)
    self.procedure_occurrence_id = value
  end

  def concept_id=(value)
    self.procedure_concept_id = value
  end

  def type_concept_id=(value)
    self.procedure_type_concept_id = value
  end

  def source_value=(value)
    self.procedure_source_value = value
  end
end