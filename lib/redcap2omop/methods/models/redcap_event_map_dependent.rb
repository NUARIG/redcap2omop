module Redcap2omop::Methods::Models::RedcapEventMapDependent
  def self.included(base)
    base.send :include, Redcap2omop::SoftDelete

    # Associations
    base.send :belongs_to, :redcap_event
    base.send :belongs_to, :redcap_variable
    base.send :belongs_to, :omop_column, optional: true
    base.send :belongs_to, :concept, optional: true
    base.send :belongs_to, :redcap_event_map

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
  end
end
