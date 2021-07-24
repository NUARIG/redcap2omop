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
        redcap_variables = []

        # Determine the curation status each Redcap variable
        data_dictionary_variables.each do |data_dictionary_variable|
          redcap_variable = Redcap2omop::RedcapVariable.new(redcap_data_dictionary: redcap_data_dictionary)
          redcap_variables << redcap_variable

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

        # Determine the curation status of each Redcap variable choice
        redcap_variables_updated_choices = redcap_data_dictionary.redcap_variables.where(curation_status: Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_CHOICES)
        redcap_variables_updated_choices.each do |redcap_variable|
          redcap_variable.redcap_variable_choices.each do |redcap_variable_choice|
            if !redcap_project.redcap_variable_choice_exists_in_redcap_data_dictionary?(redcap_variable.name, redcap_variable_choice.choice_code_raw)
              redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED_NEW_CHOICE
              redcap_variable_choice.save!
              new_data_dictionary = true
            end

            if redcap_project.redcap_variable_choice_description_changed_in_redcap_data_dictionary?(redcap_variable.name, redcap_variable_choice.choice_code_raw, redcap_variable_choice.choice_description)
              redcap_variable_choice.curation_status = Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED_UPDATED_DESCRIPTION
              redcap_variable_choice.save!
              new_data_dictionary = true
            end
          end
        end

        # Track deleted Redcap variables and Redcap variable choices
        if prior_redcap_data_dictionary
          deleted_redcap_variables = Redcap2omop::RedcapVariable.where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ? AND NOT EXISTS(SELECT 1 FROM redcap2omop_redcap_variables AS new_redcap2omop_redcap_variables WHERE new_redcap2omop_redcap_variables.redcap_data_dictionary_id = ? AND redcap2omop_redcap_variables.name = new_redcap2omop_redcap_variables.name)', prior_redcap_data_dictionary.id, redcap_data_dictionary.id)
          deleted_redcap_variables.each do |deleted_redcap_variable|
            deleted_redcap_variable.deleted_in_next_data_dictionary = true
            deleted_redcap_variable.save!
          end

          if deleted_redcap_variables.size > 0
            new_data_dictionary = true
          end

          deleted_redcap_variable_choices = Redcap2omop::RedcapVariableChoice.joins(:redcap_variable).where('redcap2omop_redcap_variables.redcap_data_dictionary_id = ? AND NOT EXISTS(SELECT 1 FROM redcap2omop_redcap_variables AS new_redcap2omop_redcap_variables JOIN redcap2omop_redcap_variable_choices AS new_redcap2omop_redcap_variable_choices ON new_redcap2omop_redcap_variables.id = new_redcap2omop_redcap_variable_choices.redcap_variable_id WHERE new_redcap2omop_redcap_variables.redcap_data_dictionary_id = ? AND redcap2omop_redcap_variables.name = new_redcap2omop_redcap_variables.name AND redcap2omop_redcap_variable_choices.choice_code_raw = new_redcap2omop_redcap_variable_choices.choice_code_raw)', prior_redcap_data_dictionary.id, redcap_data_dictionary.id)
          deleted_redcap_variable_choices.each do |deleted_redcap_variable_choice|
            deleted_redcap_variable_choice.deleted_in_next_data_dictionary = true
            deleted_redcap_variable_choice.save!
          end

          if deleted_redcap_variable_choices.size > 0
            new_data_dictionary = true
          end
        end

        # Delete the current Redcap data dictionary if nothing has changed
        if prior_redcap_data_dictionary && !new_data_dictionary
          redcap_data_dictionary.destroy!
        end

        if new_data_dictionary && prior_redcap_data_dictionary
          # Migrate Redcap derived dates with a base Redcap variable
          prior_redcap_data_dictionary.redcap_derived_dates.where('base_date_redcap_variable_id IS NOT NULL AND offset_redcap_variable_id IS NOT NULL').each do |old_redcap_derived_date|
            new_base_date_redcap_variable = redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.base_date_redcap_variable.name).first
            new_offset_redcap_variable = redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.offset_redcap_variable.name).first
            new_redcap_derived_date = Redcap2omop::RedcapDerivedDate.new(redcap_data_dictionary: redcap_data_dictionary, name: old_redcap_derived_date.name, base_date_redcap_variable_id: new_base_date_redcap_variable.id, offset_redcap_variable_id: new_offset_redcap_variable.id,  offset_interval_days: old_redcap_derived_date.offset_interval_days, offset_interval_direction: old_redcap_derived_date.offset_interval_direction)
            build_redcap_derived_date_choice_offset_mappings(new_redcap_derived_date, old_redcap_derived_date, new_offset_redcap_variable)
            new_redcap_derived_date.save!
          end
          # Migrate Redcap derived dates with a parent Redcap derived date
          prior_redcap_data_dictionary.redcap_derived_dates.where('parent_redcap_derived_date_id IS NOT NULL AND offset_redcap_variable_id IS NOT NULL').each do |old_redcap_derived_date|
            new_parent_redcap_derived_date = redcap_data_dictionary.redcap_derived_dates.where(name: old_redcap_derived_date.parent_redcap_derived_date.name).first
            new_offset_redcap_variable = redcap_data_dictionary.redcap_variables.where(name: old_redcap_derived_date.offset_redcap_variable.name).first
            new_redcap_derived_date = Redcap2omop::RedcapDerivedDate.new(redcap_data_dictionary: redcap_data_dictionary, name: old_redcap_derived_date.name, parent_redcap_derived_date_id: new_parent_redcap_derived_date.id, offset_redcap_variable_id: new_offset_redcap_variable.id, offset_interval_days: old_redcap_derived_date.offset_interval_days, offset_interval_direction: old_redcap_derived_date.offset_interval_direction)
            build_redcap_derived_date_choice_offset_mappings(new_redcap_derived_date, old_redcap_derived_date, new_offset_redcap_variable)
            new_redcap_derived_date.save!
          end

          # Migrate Redcap variable maps, Redcap variable chioce maps and Redcap variable child maps
          redcap_variables.each do |redcap_variable|
            if redcap_variable.curation_status != Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_NEW_VARIABLE
              prior_redcap_variable = prior_redcap_data_dictionary.find_redcap_variable(redcap_variable.name)
              if prior_redcap_variable
                if redcap_variable.curation_status == Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED
                  redcap_variable.curation_status = prior_redcap_variable.curation_status
                end

                if prior_redcap_variable.curation_status == Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
                  redcap_variable.curation_status = Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_SKIPPED
                end

                if prior_redcap_variable.redcap_variable_map
                  redcap_variable.build_redcap_variable_map(concept_id: prior_redcap_variable.redcap_variable_map.concept_id, omop_column_id: prior_redcap_variable.redcap_variable_map.omop_column_id, map_type: prior_redcap_variable.redcap_variable_map.map_type)
                end

                if prior_redcap_variable.redcap_variable_child_maps.any?
                  prior_redcap_variable.redcap_variable_child_maps.each do |redcap_variable_child_map|
                    if redcap_variable_child_map.redcap_variable
                      redcap_variable.redcap_variable_child_maps.build(redcap_variable: redcap_data_dictionary.redcap_variables.where(name: redcap_variable_child_map.redcap_variable.name).first, omop_column: redcap_variable_child_map.omop_column, map_type: redcap_variable_child_map.map_type)
                    end

                    if redcap_variable_child_map.redcap_derived_date_id
                      new_redcap_derived_date = redcap_data_dictionary.redcap_derived_dates.where(name: redcap_variable_child_map.redcap_derived_date.name).first
                      redcap_variable.redcap_variable_child_maps.build(redcap_derived_date: new_redcap_derived_date, omop_column: redcap_variable_child_map.omop_column, map_type: redcap_variable_child_map.map_type)
                    end

                    if redcap_variable_child_map.concept_id
                      redcap_variable.redcap_variable_child_maps.build(concept_id: redcap_variable_child_map.concept_id, omop_column: redcap_variable_child_map.omop_column, map_type: redcap_variable_child_map.map_type)
                    end
                  end
                end

                if prior_redcap_variable.redcap_variable_choices.any? && prior_redcap_variable.curation_status == Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_MAPPED
                  prior_redcap_variable.redcap_variable_choices.each do |prior_redcap_variable_choice|
                    redcap_variable_choice = redcap_variable.redcap_variable_choices.where(choice_code_raw: prior_redcap_variable_choice.choice_code_raw).first
                    if redcap_variable_choice
                      if prior_redcap_variable_choice.redcap_variable_choice_map
                        redcap_variable_choice.build_redcap_variable_choice_map(concept_id: prior_redcap_variable_choice.redcap_variable_choice_map.concept_id, map_type: prior_redcap_variable_choice.redcap_variable_choice_map.map_type)
                        redcap_variable_choice.curation_status = prior_redcap_variable_choice.curation_status
                      end

                      if prior_redcap_variable_choice.redcap_variable_child_maps.any?
                        prior_redcap_variable_choice.redcap_variable_child_maps.each do |redcap_variable_child_map|
                          if redcap_variable_child_map.redcap_variable
                            redcap_variable_choice.redcap_variable_child_maps.build(redcap_variable: redcap_data_dictionary.redcap_variables.where(name: redcap_variable_child_map.redcap_variable.name).first, omop_column: redcap_variable_child_map.omop_column, map_type: redcap_variable_child_map.map_type)
                          end

                          if redcap_variable_child_map.redcap_derived_date_id
                            new_redcap_derived_date = redcap_data_dictionary.redcap_derived_dates.where(name: redcap_variable_child_map.redcap_derived_date.name).first
                            redcap_variable_choice.redcap_variable_child_maps.build(redcap_derived_date: new_redcap_derived_date, omop_column: redcap_variable_child_map.omop_column, map_type: redcap_variable_child_map.map_type)
                          end

                          if redcap_variable_child_map.concept_id
                            redcap_variable_choice.redcap_variable_child_maps.build(concept_id: redcap_variable_child_map.concept_id, omop_column: redcap_variable_child_map.omop_column, map_type: redcap_variable_child_map.map_type)
                          end
                        end
                      end
                      redcap_variable_choice.save!
                    end
                  end
                end

                redcap_variable.save!
              end
            end
          end
        end
      end

      OpenStruct.new(success: true)
    rescue Exception => exception
      OpenStruct.new(success: false, message: exception.message, backtrace: exception.backtrace.join("\n"))
    end

    private
      def build_redcap_derived_date_choice_offset_mappings(new_redcap_derived_date, old_redcap_derived_date, new_offset_redcap_variable)
        old_redcap_derived_date.redcap_derived_date_choice_offset_mappings.each do |old_redcap_derived_date_choice_offset_mapping|
          new_redcap_variable_choice = new_offset_redcap_variable.redcap_variable_choices.where(choice_code_raw: old_redcap_derived_date_choice_offset_mapping.redcap_variable_choice.choice_code_raw).first
          if new_redcap_variable_choice
            new_redcap_derived_date.redcap_derived_date_choice_offset_mappings.build(redcap_variable_choice: new_redcap_variable_choice, offset_days: old_redcap_derived_date_choice_offset_mapping.offset_days)
          end
        end
      end
  end
end