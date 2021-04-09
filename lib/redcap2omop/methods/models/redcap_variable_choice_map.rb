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
      where('redcap2omop_redcap_variable_choice_maps.concept_id != ?', Redcap2omop::Concept::CONCEPT_ID_NO_MATCHING_CONCEPT)
    end

    def by_redcap_dictionary(redcap_data_dictionary)
      joins('JOIN redcap2omop_redcap_variable_choices ON redcap2omop_redcap_variable_choice_maps.redcap_variable_choice_id = redcap2omop_redcap_variable_choices.id JOIN redcap2omop_redcap_variables ON redcap2omop_redcap_variable_choices.redcap_variable_id = redcap2omop_redcap_variables.id JOIN redcap2omop_redcap_variable_maps ON redcap2omop_redcap_variables.id = redcap2omop_redcap_variable_maps.redcap_variable_id').where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ? AND redcap2omop_redcap_variable_maps.map_type = ? AND redcap2omop_redcap_variable_choice_maps.map_type = ?', redcap_data_dictionary.id, Redcap2omop::RedcapVariableMap::REDCAP_VARIABLE_MAP_MAP_TYPE_OMOP_CONCEPT_CHOICE, Redcap2omop::RedcapVariableChoiceMap::REDCAP_VARIABLE_CHOICE_MAP_MAP_TYPE_OMOP_CONCEPT)
    end
  end
end
