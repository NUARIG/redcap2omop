class RedcapVariableChildMap < ApplicationRecord
  belongs_to :parentable, polymorphic: true
  belongs_to :omop_column, optional: true
  belongs_to :redcap_variable, optional: true
  belongs_to :redcap_derived_date, optional: true

  REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARAIBLE = 'REDCap Variable'
  REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE = 'REDCap Derived Date'
  REDCAP_VARIABLE_CHILD_MAP_MAP_TYPES = [REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARAIBLE, REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE]
end