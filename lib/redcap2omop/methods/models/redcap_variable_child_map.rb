module Redcap2omop::Methods::Models::RedcapVariableChildMap
  def self.included(base)
    # Associations
    base.send :belongs_to, :redcap_variable
    base.send :belongs_to, :parentable, polymorphic: true
    base.send :belongs_to, :omop_column, optional: true
    base.send :belongs_to, :concept, optional: true

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
  end
end
