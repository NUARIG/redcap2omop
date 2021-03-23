module Redcap2omop::Methods::Models::OmopTable
  def self.included(base)
    base.send :include, Redcap2omop::SoftDelete

    # Associations
    base.send :has_many, :omop_columns
    base.send :accepts_nested_attributes_for, :omop_columns

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
  end
end
