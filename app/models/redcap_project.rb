class RedcapProject < ApplicationRecord
  include SoftDelete
  has_many :redcap_data_dictionaries

  def type_concept
    #Case Report Form
    Concept.where(domain_id: 'Type Concept', concept_code: 'OMOP4976882').first
  end
end