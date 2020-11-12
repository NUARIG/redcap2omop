class RedcapVariableMap < ApplicationRecord
  belongs_to :redcap_variable
  belongs_to :omop_column, optional: true
  belongs_to :concept, optional: true
end