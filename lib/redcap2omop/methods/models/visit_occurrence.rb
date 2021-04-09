module Redcap2omop::Methods::Models::VisitOccurrence
  DOMAIN_ID = 'Visit'
  MAP_TYPES = {
    visit_occurrence_id: 'primary key',
    person_id: 'person',
    visit_concept_id: 'domain concept',
    visit_start_date: 'date redcap variable|derived redcap date',
    visit_start_datetime: 'skip',
    visit_end_date: 'date redcap variable|derived redcap date',
    visit_end_datetime: 'skip',
    visit_type_concept_id:  'hardcode',
    provider_id: 'provider',
    care_site_id: 'skip',
    visit_source_value: 'redcap variable name|choice redcap variable choice description',
    visit_source_concept_id: 'skip',
    admitting_source_concept_id: 'skip',
    admitting_source_value: 'skip',
    discharge_to_concept_id: 'skip',
    discharge_to_source_value: 'skip',
    preceding_visit_occurrence_id: 'skip',

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
    base.send :belongs_to, :concept, foreign_key: :visit_concept_id
    base.send :belongs_to, :type_concept, foreign_key: :visit_type_concept_id, class_name: 'Redcap2omop::Concept'

    # Validations
    base.send :validates_presence_of, :visit_start_date
    base.send :validates_presence_of, :visit_end_date

    base.instance_eval do
      self.table_name   = 'visit_occurrence'
      self.primary_key  = 'visit_occurrence_id'
    end

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
    def instance_id=(value)
      self.visit_occurrence_id = value
    end

    def concept_id=(value)
      self.visit_concept_id = value
    end

    def type_concept_id=(value)
      self.visit_type_concept_id = value
    end

    def source_value=(value)
      self.visit_source_value = value
    end
  end

  module ClassMethods
  end
end
