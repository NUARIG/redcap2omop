class RedcapEventMap < ApplicationRecord
  include SoftDelete
  belongs_to  :redcap_event
  belongs_to  :omop_column, optional: true
  belongs_to  :concept, optional: true
  has_many    :redcap_event_map_dependents
end
