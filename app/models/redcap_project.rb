class RedcapProject < ApplicationRecord
  include SoftDelete
  has_many :redcap_data_dictionaries
  validates :export_table_name, uniqueness: true, presence: true

  after_initialize :set_export_table_name, if: :new_record?

  def type_concept
    #Case Report Form
    Concept.where(domain_id: 'Type Concept', concept_code: 'OMOP4976882').first
  end

  def set_export_table_name
    self.export_table_name ||= "redcap_records_tmp_#{self.unique_identifier}"
  end

  def unique_identifier
    if self.new_record?
      last_id = self.class.default_scoped.maximum(:id)
      last_id ||= 0
      last_id + 1
    else
      self.id
    end
  end

  scope :csv_importable, -> do
    where(api_import: false)
  end

  scope :api_importable, -> do
    where(api_import: true)
  end
end