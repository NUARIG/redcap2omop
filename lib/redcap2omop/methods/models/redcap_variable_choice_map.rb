module Redcap2omop::Methods::Models::RedcapVariableChoiceMap
  REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT = 'OMOP concept'
  REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPES = [REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT]

  def self.included(base)
    # Associations
    base.send :belongs_to, :redcap_variable_choice
    base.send :belongs_to, :omop_column, optional: true
    base.send :belongs_to, :concept, optional: true

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
    def not_no_matching_concept
      where('redcap_variable_choice_maps.concept_id != ?', Concept::CONCEPT_ID_NO_MATCHING_CONCEPT)
    end
  end
end
