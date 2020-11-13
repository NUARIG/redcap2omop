class RedcapVariableChoice < ApplicationRecord
  include SoftDelete
  belongs_to :redcap_variable
  has_one :redcap_variable_choice_map
end