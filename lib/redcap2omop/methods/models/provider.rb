module Redcap2omop::Methods::Models::Provider
  MAP_TYPES = {
    provider_id: 'primary key',
    provider_name: 'text redcap variable',
    npi: 'text redcap variable',
    dea: 'text redcap variable',
    specialty_concept_id: 'choice redcap variable',
    care_site_id: 'care_site',
    year_of_birth: 'date redcap variable year',
    gender_concept_id: 'choice redcap variable',
    provider_source_value: 'text redcap variable',
    specialty_source_value: 'choice redcap variable choice description',
    specialty_source_concept_id: 'skip',
    gender_source_value: 'choice redcap variable choice description',
    gender_source_concept_id: 'skip'
  }.freeze

  def self.included(base)
    base.send :include, Redcap2omop::WithNextId
    base.send :include, Redcap2omop::WithOmopTable
    base.send :mattr_reader, :map_types, default: MAP_TYPES

    base.send :include, InstanceMethods
    base.extend(ClassMethods)

    base.instance_eval do
      self.table_name   = 'provider'
      self.primary_key  = 'provider_id'
    end
  end

  module InstanceMethods
  end

  module ClassMethods
  end
end
