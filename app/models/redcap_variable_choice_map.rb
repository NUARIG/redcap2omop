class RedcapVariableChoiceMap < ApplicationRecord
  belongs_to :redcap_variable_choice
  belongs_to :concept, optional: true

  REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_COLUMN = 'OMOP column'
  REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT = 'OMOP concept'
  REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPES = [REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_COLUMN, REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT]

  scope :not_no_matching_concept, -> do
    where('redcap_variable_choice_maps.concept_id != ?', Concept::CONCEPT_ID_NO_MATCHING_CONCEPT)
  end
end