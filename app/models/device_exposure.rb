class DeviceExposure < ApplicationRecord
  include WithNextId
  cattr_reader :map_types

  self.table_name = 'device_exposure'
  self.primary_key = 'device_exposure_id'
  @@map_types = {
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
  }

  DOMAIN_ID = 'Device'

  has_one :redcap_source_link, as: :redcap_sourced

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