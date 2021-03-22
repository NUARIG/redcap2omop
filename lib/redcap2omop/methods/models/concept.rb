module Redcap2omop::Methods::Models::Concept
  CONCEPT_ID_NO_MATCHING_CONCEPT = 0

  CONCEPT_CODE_OMOP_GENERATED = 'OMOP generated'

  DOMAIN_ID_CONDITION = 'Condition'
  DOMAIN_ID_DRUG = 'Drug'
  DOMAIN_ID_GENDER = 'Gender'
  DOMAIN_ID_ETHNICITY = 'Ethnicity'
  DOMAIN_ID_MEASUREMENT = 'Measurement'
  DOMAIN_ID_MEAS_VALUE = 'Meas Value'
  DOMAIN_ID_METADATA = 'Metadata'
  DOMAIN_ID_NOTE = 'Note'
  DOMAIN_ID_SPECIMEN = 'Specimen'
  DOMAIN_ID_OBSERVATION = 'Observation'
  DOMAIN_ID_PROCEDURE = 'Procedure'
  DOMAIN_ID_RACE = 'Race'
  DOMAIN_ID_RELATIONSHIP = 'Relationship'
  DOMAIN_ID_ROUTE = 'Route'
  DOMAIN_ID_TYPE_CONCEPT = 'Type Concept'
  DOMAIN_ID_UNIT = 'Unit'
  DOMAIN_IDS = [DOMAIN_ID_CONDITION, DOMAIN_ID_GENDER, DOMAIN_ID_ETHNICITY, DOMAIN_ID_MEASUREMENT, DOMAIN_ID_METADATA, DOMAIN_ID_OBSERVATION, DOMAIN_ID_PROCEDURE, DOMAIN_ID_RACE, DOMAIN_ID_RELATIONSHIP, DOMAIN_ID_ROUTE, DOMAIN_ID_TYPE_CONCEPT, DOMAIN_ID_UNIT]

  VOCABULARY_ID_CONDITION_TYPE = 'Condition Type'
  VOCABULARY_ID_CPT4 = 'CPT4'
  VOCABULARY_ID_CONCEPT_CLASS = 'Concept Class'
  VOCABULARY_ID_DOMAIN = 'Domain'
  VOCABULARY_ID_DEATH_TYPE = 'Death Type'
  VOCABULARY_ID_DRUG_TYPE = 'Drug Type'
  VOCABULARY_ID_ETHNICITY = 'Ethnicity'
  VOCABULARY_ID_GENDER = 'Gender'
  VOCABULARY_ID_LOINC = 'LOINC'
  VOCABULARY_ID_MEAS_TYPE = 'Meas Type'
  VOCABULARY_ID_NOTE_TYPE = 'Note Type'
  VOCABULARY_ID_OBSERVATION_TYPE = 'Observation Type'
  VOCABULARY_ID_PROCEDURE_TYPE = 'Procedure Type'
  VOCABULARY_ID_RACE = 'Race'
  VOCABULARY_ID_RELATIONSHIP = 'Relationship'
  VOCABULARY_ID_RXNORM = 'RxNorm'
  VOCABULARY_ID_SNOMED = 'SNOMED'
  VOCABULARY_ID_SPECIMEN_TYPE = 'Specimen Type'
  VOCABULARY_ID_UCUM = 'UCUM'
  VOCABULARY_ID_NONE = 'None'
  VOCABULARY_IDS = [VOCABULARY_ID_CONDITION_TYPE, VOCABULARY_ID_CPT4, VOCABULARY_ID_CONCEPT_CLASS, VOCABULARY_ID_DOMAIN, VOCABULARY_ID_DRUG_TYPE, VOCABULARY_ID_ETHNICITY, VOCABULARY_ID_GENDER, VOCABULARY_ID_LOINC, VOCABULARY_ID_MEAS_TYPE, VOCABULARY_ID_PROCEDURE_TYPE, VOCABULARY_ID_RACE, VOCABULARY_ID_RELATIONSHIP, VOCABULARY_ID_RXNORM, VOCABULARY_ID_SNOMED, VOCABULARY_ID_SPECIMEN_TYPE, VOCABULARY_ID_UCUM, VOCABULARY_ID_NONE]

  CONCEPT_CLASS_ANSWER = 'Answer'
  CONCEPT_CLASS_CLINICAL_FINDING = 'Clinical Finding'
  CONCEPT_CLASS_CONDITION_TYPE = 'Condition Type'
  CONCEPT_CLASS_DRUG_TYPE = 'Drug Type'
  CONCEPT_CLASS_CLINICAL_DRUG = 'Clinical Drug'
  CONCEPT_CLASS_CPT4 = 'CPT4'
  CONCEPT_CLASS_DEATH_TYPE = 'Death Type'
  CONCEPT_CLASS_DOMAIN = 'Domain'
  CONCEPT_CLASS_GENDER = 'Gender'
  CONCEPT_CLASS_ETHNICITY = 'Ethnicity'
  CONCEPT_CLASS_INGREDIENT = 'Ingredient'
  CONCEPT_CLASS_LAB_TEST = 'Lab Test'
  CONCEPT_CLASS_MEAS_TYPE = 'Meas Type'
  CONCEPT_CLASS_NOTE_TYPE = 'Note Type'
  CONCEPT_CLASS_OBSERVATION_TYPE = 'Observation Type'
  CONCEPT_CLASS_PROCEDURE_TYPE = 'Procedure Type'
  CONCEPT_CLASS_QUALIFIER_VALUE = 'Qualifier Value'
  CONCEPT_CLASS_RACE = 'Race'
  CONCEPT_CLASS_RELATIONSHIP = 'Relationship'
  CONCEPT_CLASS_SPECIMEN_TYPE = 'Specimen Type'
  CONCEPT_CLASS_SURVEY = 'Survey'
  CONCEPT_CLASS_UNIT = 'Unit'
  CONCEPT_CLASS_UNDEFINED = 'Undefined'
  CONCEPT_CLASSES = [CONCEPT_CLASS_ANSWER, CONCEPT_CLASS_CLINICAL_FINDING, CONCEPT_CLASS_CONDITION_TYPE, CONCEPT_CLASS_DRUG_TYPE, CONCEPT_CLASS_CPT4, CONCEPT_CLASS_DOMAIN, CONCEPT_CLASS_GENDER, CONCEPT_CLASS_ETHNICITY, CONCEPT_CLASS_LAB_TEST, CONCEPT_CLASS_MEAS_TYPE, CONCEPT_CLASS_PROCEDURE_TYPE, CONCEPT_CLASS_QUALIFIER_VALUE, CONCEPT_CLASS_RACE, CONCEPT_CLASS_RELATIONSHIP, CONCEPT_CLASS_SPECIMEN_TYPE, CONCEPT_CLASS_SURVEY, CONCEPT_CLASS_UNIT, CONCEPT_CLASS_UNDEFINED]

  def self.included(base)
    base.instance_eval do
      self.table_name   = 'concept'
      self.primary_key  = 'concept_id'
    end

    base.send :include, Redcap2omop::WithNextId
    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
    def standard
      where(standard_concept: 'S')
    end

    def valid
      where(invalid_reason: nil)
    end

    def condition_types
      valid.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_CONDITION_TYPE,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_CONDITION_TYPE
      )
    end

    def domain_concepts
      valid.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_METADATA,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DOMAIN,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_DOMAIN
      )
    end

    def death_types
      valid.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DEATH_TYPE,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_DEATH_TYPE
      )
    end

    def drug_types
      valid.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_DRUG_TYPE,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_DRUG_TYPE
      )
    end

    def measurement_types
      valid.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_MEAS_TYPE,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_MEAS_TYPE
      )
    end

    def note_types
      valid.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_NOTE_TYPE,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_NOTE_TYPE
      )
    end

    def observation_types
      valid.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_OBSERVATION_TYPE,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_OBSERVATION_TYPE
      )
    end

    def procedure_types
      valid.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_PROCEDURE_TYPE,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_PROCEDURE_TYPE
      )
    end

    def routes
      valid.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_ROUTE,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_SNOMED,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_QUALIFIER_VALUE
      )
    end

    def units
      valid.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_UNIT,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_UCUM,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_UNIT
      )
    end

    def genders
      standard.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_GENDER,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_GENDER,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_GENDER
      )
    end

    def races
      standard.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_RACE,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_RACE,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_RACE
      )
    end

    def ethnicities
      standard.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_ETHNICITY,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_ETHNICITY ,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_ETHNICITY
      )
    end

    def procedure_concepts
      standard.valid.where(domain_id: Redcap2omop::Concept::DOMAIN_ID_PROCEDURE)
    end

    def specimen_concepts
      standard.valid.where(domain_id: Redcap2omop::Concept::DOMAIN_ID_SPECIMEN)
    end

    def specimen_types
      valid.where(
        domain_id:        Redcap2omop::Concept::DOMAIN_ID_TYPE_CONCEPT,
        vocabulary_id:    Redcap2omop::Concept::VOCABULARY_ID_SPECIMEN_TYPE,
        concept_class_id: Redcap2omop::Concept::CONCEPT_CLASS_SPECIMEN_TYPE
      )
    end
  end
end
