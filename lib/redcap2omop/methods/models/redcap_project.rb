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

    def prior_redcap_data_dictionary
      redcap_data_dictionary = nil
      prior_version = redcap_data_dictionaries.maximum(:version)
      if prior_version
        prior_version = prior_version - 1
        redcap_data_dictionary = self.redcap_data_dictionaries.where(version: prior_version).first
      end
      redcap_data_dictionary
    end

    def current_redcap_data_dictionary
      self.redcap_data_dictionaries.where(version: redcap_data_dictionaries.maximum(:version)).first
    end

    def redcap_variable_exists_in_redcap_data_dictionary?(redcap_variable_name)
      if self.prior_redcap_data_dictionary
        self.prior_redcap_data_dictionary.redcap_variable_exist?(redcap_variable_name)
      end
    end

    def redcap_variable_field_type_changed_in_redcap_data_dictionary?(redcap_variable_name, field_type, text_validation_type)
      if self.prior_redcap_data_dictionary
        self.prior_redcap_data_dictionary.redcap_variable_field_type_changed?(redcap_variable_name, field_type, text_validation_type)
      end
    end

    def redcap_variable_field_label_changed_in_redcap_data_dictionary?(redcap_variable_name, field_label)
      if self.prior_redcap_data_dictionary
        self.prior_redcap_data_dictionary.redcap_variable_field_label_changed?(redcap_variable_name, field_label)
      end
    end

    def redcap_variable_choices_changed_in_redcap_data_dictionary?(redcap_variable_name, choices)
      if self.prior_redcap_data_dictionary
        self.prior_redcap_data_dictionary.redcap_variable_choices_changed?(redcap_variable_name, choices)
      end
    end

    def redcap_variable_choice_exists_in_redcap_data_dictionary?(redcap_variable_name, choice_code_raw)
      if self.prior_redcap_data_dictionary
        self.prior_redcap_data_dictionary.redcap_variable_choice_exist?(redcap_variable_name, choice_code_raw)
      end
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