class RedcapEventMap < ApplicationRecord
  belongs_to :redcap_event
  belongs_to :omop_column, optional: true
  belongs_to :concept, optional: true
end
