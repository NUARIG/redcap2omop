module Redcap2omop::Methods::Models::RedcapDerivedDateChoiceOffsetMapping
  def self.included(base)
    # Associations
    base.send :belongs_to, :redcap_derived_date
    base.send :belongs_to, :redcap_variable_choice

    # Validations
    base.send :validates, :offset_days, presence: true

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
  end
end
