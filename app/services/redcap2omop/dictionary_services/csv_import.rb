require 'csv'
module Redcap2omop::DictionaryServices
  class CsvImport
    attr_reader :redcap_project, :csv_file, :csv_file_options

    def initialize(redcap_project:, csv_file:, csv_file_options:{})
      @redcap_project   = redcap_project
      @csv_file         = csv_file
      @csv_file_options = csv_file_options || {}
    end

    def run
      prior_redcap_data_dictionary = nil
      redcap_data_dictionary = nil
      ActiveRecord::Base.transaction do
        new_data_dictionary = false
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        prior_redcap_data_dictionary = redcap_project.prior_redcap_data_dictionary
        data_dictionary_variables = CSV.new(File.open(csv_file), **csv_file_options)
        data_dictionary_variables.each do |data_dictionary_variable|
          redcap_variable = Redcap2omop::RedcapVariable.new(redcap_data_dictionary: redcap_data_dictionary)

          if !redcap_project.redcap_variable_exists_in_redcap_data_dictionary?(data_dictionary_variable['Variable / Field Name'])
            new_data_dictionary = true
            redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_NEW_VARIABLE
          end

          redcap_variable.name                  = data_dictionary_variable['Variable / Field Name']                         #metadata_variable['field_name']
          redcap_variable.form_name             = data_dictionary_variable['Form Name']                                     #metadata_variable['form_name']

          if redcap_project.redcap_variable_field_type_changed_in_redcap_data_dictionary?(data_dictionary_variable['Variable / Field Name'], data_dictionary_variable['Field Type'], data_dictionary_variable['Text Validation Type OR Show Slider Number'])
            new_data_dictionary = true
            redcap_variable.curation_status =  Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_TYPE
          end

          redcap_variable.field_type            = data_dictionary_variable['Field Type']                                    #metadata_variable['field_type']
          redcap_variable.text_validation_type  = data_dictionary_variable['Text Validation Type OR Show Slider Number']    #metadata_variable['text_validation_type_or_show_slider_number']

          if redcap_project.redcap_variable_field_label_changed_in_redcap_data_dictionary?(data_dictionary_variable['Variable / Field Name'], data_dictionary_variable['Field Label'])
            new_data_dictionary = true
            redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_LABEL
          end

          redcap_variable.field_label           = data_dictionary_variable['Field Label']                                   #metadata_variable['field_label']

          if redcap_project.redcap_variable_choices_changed_in_redcap_data_dictionary?(data_dictionary_variable['Variable / Field Name'], data_dictionary_variable['Choices, Calculations, OR Slider Labels'])
            new_data_dictionary = true
            redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_CHOICES
          end

          redcap_variable.choices               = data_dictionary_variable['Choices, Calculations, OR Slider Labels']       #metadata_variable['select_choices_or_calculations']
          redcap_variable.field_annotation      = data_dictionary_variable['Field Annotation']                              #metadata_variable['field_annotation']
          redcap_variable.save!
        end
        if prior_redcap_data_dictionary && !new_data_dictionary
          redcap_data_dictionary.destroy!
        end
      end

      redcap_variables = redcap_data_dictionary.redcap_variables.where(curation_status: Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_CHOICES)
      redcap_variables.each do |redcap_variable|
        redcap_variable.redcap_variable_choices.each do |redcap_variable_choice|
          if !redcap_project.redcap_variable_choice_exists_in_redcap_data_dictionary?(redcap_variable, redcap_variable_choice.choice_code_raw)
            redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED_NEW_CHOICE
            redcap_variable_choice.save!
          end
        end
      end

      OpenStruct.new(success: true)
    rescue Exception => exception
      OpenStruct.new(success: false, message: exception.message, backtrace: exception.backtrace.join("\n"))
    end
  end
end