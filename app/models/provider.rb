class Provider < ApplicationRecord
  self.table_name = 'provider'
  self.primary_key = 'provider_id'

  def self.next_provider_id
    provider_id = Provider.maximum(:provider_id)
    if provider_id.nil?
      provider_id = 1
    else
      provider_id+=1
    end
    provider_id
  end
end