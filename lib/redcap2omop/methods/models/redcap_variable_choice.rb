module Redcap2omop::Methods::Models::RedcapVariableChoice
  def self.included(base)
    base.send :include, Redcap2omop::SoftDelete

    # Associations
    base.send :belongs_to, :redcap_variable
    base.send :has_one, :redcap_variable_choice_map

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
  end
end
