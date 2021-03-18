module Redcap2omop::DictionaryServices
  class RedcapImport
    attr_reader :redcap_project

    def initialize(redcap_project:)
      @redcap_project   = redcap_project
    end

    def run
      ActiveRecord::Base.transaction do
        raise 'project api token is missing' if redcap_project.api_token.blank?

        redcap_webservice = Redcap2omop::Webservices::RedcapApi.new(api_token: redcap_project.api_token)
        metadata_response = redcap_webservice.metadata
        raise "error retrieving metadata data from REDCap: #{metadata_response[:error]}" if metadata_response[:error]

        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        metadata_response[:response].each do |metadata_variable|
          redcap_variable = Redcap2omop::RedcapVariable.new(redcap_data_dictionary_id: redcap_data_dictionary.id)
          redcap_variable.name                  = metadata_variable['field_name']
          redcap_variable.form_name             = metadata_variable['form_name']
          redcap_variable.field_type            = metadata_variable['field_type']
          redcap_variable.text_validation_type  = metadata_variable['text_validation_type_or_show_slider_number']
          redcap_variable.field_type_normalized = redcap_variable.normalize_field_type
          redcap_variable.field_label           = metadata_variable['field_label']
          redcap_variable.choices               = metadata_variable['select_choices_or_calculations']
          redcap_variable.field_annotation      = metadata_variable['field_annotation']
          # redcap_variable.ordinal_position
          # redcap_variable.curated
          redcap_variable.save!
        end
      end
      OpenStruct.new(success: true)
    rescue Exception => exception
      OpenStruct.new(success: false, message: exception.message, backtrace: exception.backtrace.join("\n"))
    end
  end
end
