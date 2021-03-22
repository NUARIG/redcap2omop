module Redcap2omop::Methods::Models::ProcedureOccurrence
  DOMAIN_ID = 'Procedure'
  MAP_TYPES = {
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
  }.freeze

  def self.included(base)
    base.send :include, Redcap2omop::WithNextId
    base.send :include, Redcap2omop::WithOmopTable

    base.send :mattr_reader, :map_types, default: MAP_TYPES
    base.send :mattr_reader, :domain, default: DOMAIN_ID

    # Associations
    base.send :has_one, :redcap_source_link, as: :redcap_sourced
    base.send :belongs_to, :person
    base.send :belongs_to, :provider, optional: true
    base.send :belongs_to, :concept, foreign_key: :procedure_concept_id
    base.send :belongs_to, :type_concept, foreign_key: :procedure_type_concept_id, class_name: 'Redcap2omop::Concept'

    # Validations
    base.send :validates_presence_of, :procedure_date

    base.instance_eval do
      self.table_name   = 'procedure_occurrence'
      self.primary_key  = 'procedure_occurrence_id'
    end

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
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

  module ClassMethods
  end
end
