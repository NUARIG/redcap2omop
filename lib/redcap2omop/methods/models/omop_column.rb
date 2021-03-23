module Redcap2omop::Methods::Models::OmopColumn
  def self.included(base)
    base.send :include, Redcap2omop::SoftDelete

    # Associations
    base.send :belongs_to, :omop_table

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
  end
end
