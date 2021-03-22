module Redcap2omop::Methods::Models::DeviceExposure
  DOMAIN_ID = 'Device'
  MAP_TYPES = {
    device_exposure_id: 'primary key',
    person_id: 'person',
    device_concept_id: 'domain concept',
    device_exposure_start_date: 'date redcap variable|derived redcap date',
    device_exposure_start_datetime: 'skip',
    device_exposure_end_date: 'date redcap variable|derived redcap date',
    device_exposure_end_datetime: 'skip',
    device_type_concept_id:  'hardcode',
    unique_device_id: 'skip',
    quantity: 'skip',
    provider_id: 'provider',
    visit_occurrence_id: 'visit_occurrence',
    visit_detail_id: 'skip',
    device_source_value: 'redcap variable name|choice redcap variable choice description',
    device_source_concept_id: 'skip'
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
    base.send :belongs_to, :concept, foreign_key: :device_concept_id
    base.send :belongs_to, :type_concept, foreign_key: :device_type_concept_id, class_name: 'Redcap2omop::Concept'

    # Validations
    base.send :validates_presence_of, :device_exposure_start_date

    base.instance_eval do
      self.table_name   = 'device_exposure'
      self.primary_key  = 'device_exposure_id'
    end

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
    def instance_id=(value)
      self.device_exposure_id = value
    end

    def concept_id=(value)
      self.device_concept_id = value
    end

    def type_concept_id=(value)
      self.device_type_concept_id = value
    end

    def source_value=(value)
      self.device_source_value = value
    end
  end

  module ClassMethods
  end
end
