class RedcapSourceLink < ApplicationRecord
  belongs_to :redcap_source, polymorphic: true
  belongs_to :redcap_sourced, polymorphic: true
end
