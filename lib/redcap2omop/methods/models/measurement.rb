module Redcap2omop::Methods::Models::Measurement
  DOMAIN_ID = 'Measurement'
  MAP_TYPES = {
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
    base.send :belongs_to, :concept, foreign_key: :measurement_concept_id
    base.send :belongs_to, :type_concept, foreign_key: :measurement_type_concept_id, class_name: 'Redcap2omop::Concept'
    base.send :belongs_to, :value_as_concept, foreign_key: :value_as_concept_id, class_name: 'Redcap2omop::Concept', optional: true

    # Validations
    base.send :validates_presence_of, :measurement_date

    base.instance_eval do
      self.table_name   = 'measurement'
      self.primary_key  = 'measurement_id'
    end

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
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

  module ClassMethods
  end
end
