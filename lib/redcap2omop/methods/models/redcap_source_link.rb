module Redcap2omop::Methods::Models::RedcapSourceLink
  def self.included(base)
    # Associations
    base.send :belongs_to, :redcap_source, polymorphic: true
    base.send :belongs_to, :redcap_sourced, polymorphic: true

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
  end
end
