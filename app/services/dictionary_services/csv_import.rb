require 'csv'
module DictionaryServices
  class CsvImport
    attr_reader :redcap_project, :csv_file, :cvs_file_options

    def initialize(redcap_project:, csv_file:, csv_file_options:nil)
      @redcap_project   = redcap_project
      @csv_file         = csv_file
      @csv_file_options = csv_file_options || {}
    end

    def run
      ActiveRecord::Base.transaction do
        redcap_data_dictionary = redcap_project.redcap_data_dictionaries.create
        data_dictionary_variables = CSV.new(File.open(csv_file), **cvs_file_options)
        data_dictionary_variables.each do |data_dictionary_variable|
          redcap_variable = RedcapVariable.new(redcap_data_dictionary_id: redcap_data_dictionary.id)
          redcap_variable.name                  = data_dictionary_variable['Variable / Field Name']                         #metadata_variable['field_name']
          redcap_variable.form_name             = data_dictionary_variable['Form Name']                                     #metadata_variable['form_name']
          redcap_variable.field_type            = data_dictionary_variable['Field Type']                                    #metadata_variable['field_type']
          redcap_variable.text_validation_type  = data_dictionary_variable['Text Validation Type OR Show Slider Number']    #metadata_variable['text_validation_type_or_show_slider_number']
          redcap_variable.field_type_normalized = redcap_variable.normalize_field_type
          redcap_variable.field_label           = data_dictionary_variable['Field Label']                                   #metadata_variable['field_label']
          redcap_variable.choices               = data_dictionary_variable['Choices, Calculations, OR Slider Labels']       #metadata_variable['select_choices_or_calculations']
          redcap_variable.field_annotation      = data_dictionary_variable['Field Annotation']                              #metadata_variable['field_annotation']
          redcap_variable.save!
        end
      end
      OpenStruct.new(success: true)
    rescue Exception => exception
      OpenStruct.new(success: false, message: exception, backtrace: exception.backtrace.join("\n"))
    end
  end
end
