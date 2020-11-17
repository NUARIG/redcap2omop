class RedcapEvent < ApplicationRecord
  include SoftDelete
  has_many    :redcap_event_maps
  belongs_to  :redcap_data_dictionary
end
