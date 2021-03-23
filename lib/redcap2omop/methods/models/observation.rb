module Redcap2omop::Methods::Models::Observation
  DOMAIN_ID = 'Observation'
  MAP_TYPES = {
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
  }.freeze

  def self.included(base)
    base.send :include, Redcap2omop::WithNextId
    base.send :include, Redcap2omop::WithOmopTable

    base.instance_eval do
      self.table_name   = 'observation'
      self.primary_key  = 'observation_id'
    end

    base.send :mattr_reader, :map_types, default: MAP_TYPES
    base.send :mattr_reader, :domain, default: DOMAIN_ID

    # Associations
    base.send :has_one, :redcap_source_link, as: :redcap_sourced
    base.send :belongs_to, :person
    base.send :belongs_to, :provider, optional: true
    base.send :belongs_to, :concept, foreign_key: :observation_concept_id
    base.send :belongs_to, :type_concept, foreign_key: :observation_type_concept_id, class_name: 'Redcap2omop::Concept'
    base.send :belongs_to, :value_as_concept, foreign_key: :value_as_concept_id, class_name: 'Redcap2omop::Concept', optional: true

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
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

  module ClassMethods
  end
end
