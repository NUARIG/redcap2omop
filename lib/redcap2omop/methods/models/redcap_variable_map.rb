module Redcap2omop::Methods::Models::RedcapVariableMap
  def self.included(base)
    # Associations
    base.send :belongs_to, :redcap_variable
    base.send :belongs_to, :omop_column, optional: true
    base.send :belongs_to, :concept, optional: true

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
  end

  module ClassMethods
    def by_omop_table(omop_table)
      joins(omop_column: :omop_table).where('redcap2omop_omop_tables.name = ?', omop_table)
    end

    def by_redcap_dictionary(redcap_data_dictionary)
      joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ?', redcap_data_dictionary.id)
    end
  end
end
