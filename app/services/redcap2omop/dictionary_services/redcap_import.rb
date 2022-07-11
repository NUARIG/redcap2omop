module Redcap2omop::DictionaryServices
  class RedcapImport
    attr_reader :redcap_project

    def initialize(redcap_project:)
      @redcap_project   = redcap_project
    end

    def run
      prior_redcap_data_dictionary = nil
      redcap_data_dictionary = nil
      ActiveRecord::Base.transaction do
        raise 'project api token is missing' if redcap_project.api_token.blank?
        redcap_webservice = Redcap2omop::Webservices::RedcapApi.new(api_token: redcap_project.api_token)
        metadata_response = redcap_webservice.metadata
        raise "error retrieving metadata data from REDCap: #{metadata_response[:error]}" if metadata_response[:error]
        new_data_dictionary = false
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        prior_redcap_data_dictionary = redcap_project.prior_redcap_data_dictionary
        data_dictionary_variables = metadata_response[:response]
        redcap_variables = []
        data_dictionary_variables.each do |data_dictionary_variable|
          redcap_variable = Redcap2omop::RedcapVariable.new(redcap_data_dictionary: redcap_data_dictionary)
          redcap_variables << redcap_variable
          if !redcap_project.redcap_variable_exists_in_redcap_data_dictionary?(data_dictionary_variable['field_name'])
            new_data_dictionary = true
            redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_NEW_VARIABLE
          end
          redcap_variable.name                  = data_dictionary_variable['field_name']
          redcap_variable.form_name             = data_dictionary_variable['form_name']
          redcap_variable.field_type            = data_dictionary_variable['field_type']
          redcap_variable.text_validation_type  = data_dictionary_variable['text_validation_type_or_show_slider_number']
          redcap_variable.field_type_normalized = redcap_variable.normalize_field_type
          redcap_variable.field_label           = data_dictionary_variable['field_label']
          redcap_variable.choices               = data_dictionary_variable['select_choices_or_calculations']
          redcap_variable.field_annotation      = data_dictionary_variable['field_annotation']
          redcap_variable.save!
        end
      # Delete the current Redcap data dictionary if nothing has changed
        if prior_redcap_data_dictionary && !new_data_dictionary
          redcap_data_dictionary.destroy!
        end
      end
      OpenStruct.new(success: true)
    rescue Exception => exception
      OpenStruct.new(success: false, message: exception.message, backtrace: exception.backtrace.join("\n"))
    end
  end
end

