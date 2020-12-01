class RedcapProject < ApplicationRecord
  include SoftDelete
  has_many :redcap_data_dictionaries

  after_initialize :set_export_table_name, if: :new_record?

  def type_concept
    #Case Report Form
    Concept.where(domain_id: 'Type Concept', concept_code: 'OMOP4976882').first
  end

  def set_export_table_name
    self.export_table_name ||= "redcap_records_tmp_#{self.unique_identifier}"
  end

  def unique_identifier
    self.id
  end
end
