class RedcapEventMapDependent < ApplicationRecord
  belongs_to :redcap_event
  belongs_to :redcap_variable
  belongs_to :omop_column, optional: true
  belongs_to :concept, optional: true
  belongs_to :redcap_event_map
end
