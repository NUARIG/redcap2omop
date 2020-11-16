class Observation < ApplicationRecord
  self.table_name = 'observation'
  self.primary_key = 'observation_id'
  DOMAIN_ID = 'Observation'

  def self.next_observation_id
    observation_id = Observation.maximum(:observation_id)
    if observation_id.nil?
      observation_id = 1
    else
      observation_id+=1
    end
    observation_id
  end
end