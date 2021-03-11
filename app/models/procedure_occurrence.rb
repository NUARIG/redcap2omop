class ProcedureOccurrence < ApplicationRecord
  include WithNextId

  self.table_name = 'procedure_occurrence'
  self.primary_key = 'procedure_occurrence_id'

  DOMAIN_ID = 'Procedure'

  has_one :redcap_source_link, as: :redcap_sourced
end