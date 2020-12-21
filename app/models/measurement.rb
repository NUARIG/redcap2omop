class Measurement < ApplicationRecord
  has_one :redcap_source_link, as: :redcap_sourced

  self.table_name = 'measurement'
  self.primary_key = 'measurement_id'
  DOMAIN_ID = 'Measurement'

  def self.next_measurement_id
    measurement_id = Measurement.maximum(:measurement_id)
    if measurement_id.nil?
      measurement_id = 1
    else
      measurement_id+=1
    end
    measurement_id
  end
end
