module Redcap2omop::Methods::Models::RedcapDerivedDate
  def self.included(base)
    # Associations
    base.send :has_many, :redcap_derived_date_choice_offset_mappings
    base.send :belongs_to, :offset_redcap_variable,     class_name: 'RedcapVariable',    foreign_key: 'offset_redcap_variable_id'
    base.send :belongs_to, :base_date_redcap_variable,  class_name: 'RedcapVariable',    foreign_key: 'base_date_redcap_variable_id',  optional: true
    base.send :belongs_to, :parent_redcap_derived_date, class_name: 'RedcapDerivedDate', foreign_key: 'parent_redcap_derived_date_id', optional: true

    # Validations
    base.send :validates_presence_of, :offset_redcap_variable_id, :name

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
  end
end
