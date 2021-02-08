class RedcapDerivedDate < ApplicationRecord
  has_many :redcap_derived_date_choice_offset_mappings
  belongs_to :base_date_redcap_varaible, class_name: 'RedcapVariable', foreign_key: 'base_date_redcap_varaible_id'
  belongs_to :offset_redcap_varaible, class_name: 'RedcapVariable', foreign_key: 'offset_redcap_varaible_id'
end