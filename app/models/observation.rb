class Observation < ApplicationRecord
  self.table_name = 'observation'
  self.primary_key = 'observation_id'
  DOMAIN_ID = 'Observation'
end