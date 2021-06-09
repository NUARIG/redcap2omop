module Redcap2omop::Methods::Models::RedcapProject
  def self.included(base)
    base.send :include, Redcap2omop::SoftDelete

    # Associations
    base.send :has_many, :redcap_data_dictionaries

    # Validations
    base.send :validates, :export_table_name, uniqueness: true, presence: true

    # Hooks
    base.send :after_initialize, :set_export_table_name, if: :new_record?
    base.send :after_save, :set_export_table_name

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
    def type_concept
      #Case Report Form
      Redcap2omop::Concept.where(domain_id: 'Type Concept', concept_code: 'OMOP4976882').first
    end

    def set_export_table_name
      if self.id
        self.export_table_name = "redcap_records_tmp_#{self.id}" unless self.export_table_name == "redcap_records_tmp_#{self.id}"
      end
      self.export_table_name ||= "redcap_records_tmp_#{self.unique_identifier}"
    end

    def unique_identifier
      if self.new_record?
        last_id = self.class.default_scoped.maximum(:id)
        last_id ||= 0
        last_id + 1
      else
        self.id
      end
    end

    def current_redcap_data_dictionary
      self.redcap_data_dictionaries.where(version: redcap_data_dictionaries.maximum(:version)).first
    end
  end

  module ClassMethods
    def csv_importable
      where(api_import: false)
    end

    def api_importable
      where(api_import: true)
    end
  end
end