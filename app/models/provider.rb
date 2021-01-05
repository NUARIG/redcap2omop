class Provider < ApplicationRecord
  include WithNextId

  self.table_name  = 'provider'
  self.primary_key = 'provider_id'
end
