module Redcap2omop::Methods::Models::RedcapVariableChoiceMap
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
  end
end
