class RedcapDerivedDate < ApplicationRecord
  has_many :redcap_derived_date_choice_offset_mappings
  belongs_to :base_date_redcap_variable, class_name: 'RedcapVariable', foreign_key: 'base_date_redcap_variable_id', optional: true
  belongs_to :parent_redcap_derived_date, class_name: 'RedcapDerivedDate', foreign_key: 'parent_redcap_derived_date_id', optional: true
  belongs_to :offset_redcap_variable, class_name: 'RedcapVariable', foreign_key: 'offset_redcap_variable_id'
end