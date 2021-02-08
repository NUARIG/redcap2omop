class RedcapVariableMap < ApplicationRecord
  belongs_to :redcap_variable
  belongs_to :omop_column, optional: true
  belongs_to :concept, optional: true

  REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN = 'OMOP column'
  REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT = 'OMOP concept'
  REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE = 'OMOP concept choice'
  REDCAP_VARIABLE_MAP_MAP_TYPES = [REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_COLUMN, REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT, REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE]

  scope :by_omop_table,         ->(omop_table) { joins(omop_column: :omop_table).where('omop_tables.name = ?', omop_table)}
  scope :by_redcap_dictionary,  ->(redcap_data_dictionary) { joins(:redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id)}
end
