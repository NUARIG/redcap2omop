class RedcapDataDictionary < ApplicationRecord
  include SoftDelete
  belongs_to :redcap_project
  has_many :redcap_variables
end