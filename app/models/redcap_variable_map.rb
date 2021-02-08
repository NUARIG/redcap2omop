class RedcapVariableMap < ApplicationRecord
  belongs_to :redcap_variable
  belongs_to :omop_column, optional: true
  belongs_to :concept, optional: true

  scope :by_omop_table,         ->(omop_table) { joins(omop_column: :omop_table).where('omop_tables.name = ?', omop_table)}
  scope :by_redcap_dictionary,  ->(redcap_data_dictionary) { joins(:redcap_variable).where('redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id)}
end
