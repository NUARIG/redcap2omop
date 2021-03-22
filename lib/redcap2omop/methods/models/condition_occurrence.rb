module Redcap2omop::Methods::Models::ConditionOccurrence
  DOMAIN_ID = 'Condition'
  MAP_TYPES = {
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
    base.send :belongs_to, :concept, foreign_key: :condition_concept_id
    base.send :belongs_to, :type_concept, foreign_key: :condition_type_concept_id, class_name: 'Redcap2omop::Concept'

    # Validations
    base.send :validates_presence_of, :condition_start_date

    base.instance_eval do
      self.table_name   = 'condition_occurrence'
      self.primary_key  = 'condition_occurrence_id'
    end

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
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

  module ClassMethods
  end
end
