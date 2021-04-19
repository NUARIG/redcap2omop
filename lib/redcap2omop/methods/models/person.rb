module Redcap2omop::Methods::Models::Person
  MAP_TYPES = {
    person_id: 'primary key',
    gender_concept_id: 'choice redcap variable',
    year_of_birth: 'date redcap variable year',
    month_of_birth: 'date redcap variable month',
    day_of_birth: 'date redcap variable month day',
    birth_datetime: 'date redcap variable month',
    race_concept_id: 'choice redcap variable',
    ethnicity_concept_id: 'choice redcap variable',
    location_id: 'skip',
    provider_id: 'skip',
    care_site_id: 'skip',
    person_source_value: 'record_id',
    gender_source_value: 'choice redcap variable choice description',
    gender_source_concept_id: 'skip',
    race_source_value: 'choice redcap variable choice description',
    race_source_concept_id: 'skip',
    ethnicity_source_value: 'choice redcap variable choice description',
    ethnicity_source_concept_id: 'skip'
  }.freeze

  def self.included(base)
    base.send :include, Redcap2omop::WithNextId
    base.send :include, Redcap2omop::WithOmopTable
    base.send :mattr_reader, :map_types, default: MAP_TYPES

    # Associations
    base.send :has_many, :observations, class_name: 'Redcap2omop::Observation'

    # Validations
    base.send :validates_presence_of, :gender_concept_id, :year_of_birth, :race_concept_id, :ethnicity_concept_id
    base.send :before_validation, :set_birth_fields

    base.send :include, InstanceMethods
    base.extend(ClassMethods)

    base.instance_eval do
      self.table_name   = 'person'
      self.primary_key  = 'person_id'
    end
  end

  module InstanceMethods
    def set_birth_fields
      if self.birth_datetime.present?
        self.year_of_birth  = self.birth_datetime.year
        self.month_of_birth = self.birth_datetime.month
        self.day_of_birth   = self.birth_datetime.day
      end
    end
  end

  module ClassMethods
  end
end
