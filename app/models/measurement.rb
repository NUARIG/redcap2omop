class Measurement < ApplicationRecord
  include WithNextId

  self.table_name = 'measurement'
  self.primary_key = 'measurement_id'

  DOMAIN_ID = 'Measurement'

  has_one :redcap_source_link, as: :redcap_sourced
end
