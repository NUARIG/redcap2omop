class Observation < ApplicationRecord
  include WithNextId

  self.table_name   = 'observation'
  self.primary_key  = 'observation_id'

  DOMAIN_ID = 'Observation'

  has_one :redcap_source_link, as: :redcap_sourced
end
