class RedcapDerivedDateChoiceOffsetMapping < ApplicationRecord
  belongs_to :redcap_variable_derived_date
  belongs_to :redcap_variable_choice
end