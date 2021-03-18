module Redcap2omop::Methods::Models::RedcapEvent
  def self.included(base)
    base.send :include, Redcap2omop::SoftDelete

    # Associations
    base.send :belongs_to, :redcap_data_dictionary
    base.send :has_many, :redcap_event_maps

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
  end
end
