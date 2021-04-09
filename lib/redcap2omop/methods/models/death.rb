module Redcap2omop::Methods::Models::Death
  MAP_TYPES = {
    person_id: 'record_id',
    death_date: 'date redcap variable',
    death_datetime: 'skip',
    death_type_concept_id: 'choice redcap variable',
    cause_concept_id: 'choice redcap variable',
    cause_source_value: 'skip',
    cause_source_concept_id: 'skip'
  }.freeze

  def self.included(base)
    base.send :include, Redcap2omop::WithOmopTable
    base.send :mattr_reader, :map_types, default: MAP_TYPES

    base.send :include, InstanceMethods
    base.extend(ClassMethods)

    # Associations
    base.send :has_one, :redcap_source_link, as: :redcap_sourced
    base.send :belongs_to, :person
    base.send :belongs_to, :type_concept, foreign_key: :death_type_concept_id, class_name: 'Redcap2omop::Concept'

    # Validations
    base.send :validates_presence_of, :death_date

    base.instance_eval do
      self.table_name   = 'death'
      self.primary_key  = 'person_id'
    end
  end

  module InstanceMethods
  end

  module ClassMethods
  end
end
