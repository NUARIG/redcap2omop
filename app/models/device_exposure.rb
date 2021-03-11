class DeviceExposure < ApplicationRecord
  include WithNextId

  self.table_name = 'device_exposure'
  self.primary_key = 'device_exposure_id'

  DOMAIN_ID = 'Device'

  has_one :redcap_source_link, as: :redcap_sourced
end
