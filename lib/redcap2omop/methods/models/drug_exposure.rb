module Redcap2omop::Methods::Models::DrugExposure
  DOMAIN_ID = 'Drug'
  MAP_TYPES = {
    drug_exposure_id: 'primary key',
    person_id: 'person',
    drug_concept_id: 'domain concept',
    drug_exposure_start_date: 'date redcap variable|derived redcap date',
    drug_exposure_start_datetime: 'skip',
    drug_exposure_end_date: 'date redcap variable|derived redcap date',
    drug_exposure_end_datetime: 'skip',
    verbatim_end_date: 'skip',
    drug_type_concept_id:  'hardcode',
    stop_reason: 'skip',
    refills: 'skip',
    quantity: 'skip',
    days_supply: 'skip',
    sig: 'skip',
    route_concept_id: 'skip',
    lot_number: 'skip',
    provider_id: 'provider',
    visit_occurrence_id: 'visit_occurrence',
    visit_detail_id: 'skip',
    drug_source_value: 'redcap variable name|choice redcap variable choice description',
    drug_source_concept_id: 'skip',
    route_source_value: 'skip',
    dose_unit_source_value: 'skip'
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
    base.send :belongs_to, :concept, foreign_key: :drug_concept_id
    base.send :belongs_to, :type_concept, foreign_key: :drug_type_concept_id, class_name: 'Redcap2omop::Concept'

    # Validations
    base.send :validates_presence_of, :drug_exposure_start_date

    base.instance_eval do
      self.table_name   = 'drug_exposure'
      self.primary_key  = 'drug_exposure_id'
    end

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
    def instance_id=(value)
      self.drug_exposure_id = value
    end

    def concept_id=(value)
      self.drug_concept_id = value
    end

    def type_concept_id=(value)
      self.drug_type_concept_id = value
    end

    def source_value=(value)
      self.drug_source_value = value
    end
  end

  module ClassMethods
  end
end
