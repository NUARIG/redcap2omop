class RedcapEvent < ApplicationRecord
  include SoftDelete
  has_many :redcap_event_maps
end
