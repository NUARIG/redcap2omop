class ConditionOccurrence < ApplicationRecord
  include WithNextId

  self.table_name = 'condition_occurrence'
  self.primary_key = 'condition_occurrence_id'

  DOMAIN_ID = 'Condition'

  has_one :redcap_source_link, as: :redcap_sourced
end
