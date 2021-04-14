module Redcap2omop::DataServices
  class RedcapToOmop
    attr_reader :redcap_project, :redcap_data_dictionary, :redcap_variables, :person_redcap2omop_map,
                :provider_redcap2omop_map, :redcap_records, :logger

    def initialize(redcap_project:)
      @redcap_project           = redcap_project
      @redcap_data_dictionary   = Redcap2omop::RedcapDataDictionary.find(redcap_project.redcap_data_dictionaries.maximum(:id))
      @redcap_variables         = redcap_data_dictionary.redcap_variables
      @person_redcap2omop_map   = {}
      @provider_redcap2omop_map = {}
      @redcap_records           = []
      @logger                   = Logger.new("#{Rails.root}/log/redcap_to_omop.log")
    end

    def run
      ActiveRecord::Base.transaction do
        log_message "Converting data for #{redcap_project.name} project"
        set_person_redcap2omop_map
        set_provider_redcap2omop_map

        raise 'could not set person_redcap2omop_map mapping'    if person_redcap2omop_map.empty?
        raise 'could not set provider_redcap2omop_map mapping'  if provider_redcap2omop_map.empty?

        @redcap_records = ActiveRecord::Base.connection.select_all("select * from #{redcap_project.export_table_name}").to_a
        @redcap_records.each do |redcap_record|
          insert_person_record(redcap_record) if redcap_project.insert_person
          insert_provider_record(redcap_record)
        end
        parse_redcap_data
      end
      OpenStruct.new(success: true)
    rescue Exception => exception
      OpenStruct.new(success: false, message: exception.message, backtrace: exception.backtrace.join("\n"))
    end

    private

    def set_person_redcap2omop_map
      redcap_variable_maps = Redcap2omop::RedcapVariableMap.includes(:redcap_variable, :omop_column).by_omop_table('person').by_redcap_dictionary(redcap_data_dictionary)
      redcap_variable_maps.each do |redcap_variable_map|
        person_redcap2omop_map[redcap_variable_map.omop_column.name] = redcap_variable_map.redcap_variable.name
      end
    end

    def set_provider_redcap2omop_map
      redcap_variable_maps = Redcap2omop::RedcapVariableMap.by_omop_table('provider').by_redcap_dictionary(redcap_data_dictionary).includes(
        redcap_variable: { redcap_variable_child_maps: [:omop_column, :redcap_variable]}
      )
      redcap_variable_maps.each do |redcap_variable_map|
        provider_redcap2omop_map[redcap_variable_map.omop_column.name] ||= []
        hash = { source: redcap_variable_map.redcap_variable.name }
        redcap_variable_map.redcap_variable.redcap_variable_child_maps.each do |redcap_variable_child_map|
          hash[:variable_children] ||= []
          hash[:variable_children] << { redcap_variable_child_map.omop_column.name => redcap_variable_child_map.redcap_variable.name }
        end
        provider_redcap2omop_map[redcap_variable_map.omop_column.name] << hash
      end
    end

    def insert_person_record(redcap_record)
      person_source_value = redcap_record[person_redcap2omop_map['person_source_value']]
      return unless person_source_value && redcap_record[person_redcap2omop_map['birth_datetime']].present? || redcap_record[person_redcap2omop_map['year_of_birth']].present?

      person = Redcap2omop::Person.where(person_source_value: person_source_value).first
      if person.present?
        log_message("Person with source_value #{person_source_value} already exists")
      else
        log_message("Person with source_value #{person_source_value} will be created")
        person = Redcap2omop::Person.new(person_id: Redcap2omop::Person.next_id, person_source_value: person_source_value)
        if redcap_record[person_redcap2omop_map['birth_datetime']].present?
          log_message("REDCap birth_datetime: #{redcap_record[person_redcap2omop_map['birth_datetime']]} parsed to #{DateTime.parse(redcap_record[person_redcap2omop_map['birth_datetime']])}")
          person.birth_datetime = DateTime.parse(redcap_record[person_redcap2omop_map['birth_datetime']])
        end

        if redcap_record[person_redcap2omop_map['year_of_birth']].present?
          log_message("REDCap year_of_birth: #{redcap_record[person_redcap2omop_map['year_of_birth']]}")
          person.year_of_birth = redcap_record[person_redcap2omop_map['year_of_birth']]
        end

        log_message("REDCap gender_concept_id: #{redcap_record[person_redcap2omop_map['gender_concept_id']]}")
        redcap_variable = redcap_variables.get_by_name(person_redcap2omop_map['gender_concept_id'])
        person.gender_concept_id = redcap_variable.map_redcap_variable_choice_to_concept(redcap_record) if redcap_variable

        log_message("REDCap race_concept_id: #{redcap_record[person_redcap2omop_map['race_concept_id']]}")
        redcap_variable = redcap_variables.get_by_name(person_redcap2omop_map['race_concept_id'])
        person.race_concept_id = redcap_variable.map_redcap_variable_choice_to_concept(redcap_record) if redcap_variable

        log_message("REDCap ethnicity_concept_id: #{redcap_record[person_redcap2omop_map['ethnicity_concept_id']]}")
        redcap_variable = redcap_variables.get_by_name(person_redcap2omop_map['ethnicity_concept_id'])
        person.ethnicity_concept_id = redcap_variable.map_redcap_variable_choice_to_concept(redcap_record) if redcap_variable

        if person.valid?
          log_message("We are creating this person")
          person.save!
        else
          log_error("We are not creating this person: #{person.errors.full_messages}")
        end
      end
    end

    def insert_provider_record(redcap_record)
      provider_redcap2omop_map['provider_source_value'].each do |provider_source_value_hash|
        provider_source_value = redcap_record[provider_source_value_hash[:source]]
        if provider_source_value.present?
          provider = Redcap2omop::Provider.where(provider_source_value: provider_source_value).first
          if provider.present?
            log_message("Provider with source_value #{provider_source_value} already exists")
          else
            log_message("Provider with source_value #{provider_source_value} will be created")
            provider_name_source  = provider_source_value_hash[:variable_children].detect{|c| c.keys.include?('provider_name')}
            provider = Redcap2omop::Provider.new(provider_id: Redcap2omop::Provider.next_id, provider_source_value: provider_source_value)
            provider.provider_name = redcap_record[provider_name_source['provider_name']]
            if provider.valid?
              log_message("We are creating this provider")
              provider.save!
            else
              log_error("We are not creating this provider: #{provider.errors.full_messages}")
            end
          end
        end
      end
    end

    def parse_redcap_data
      redcap_variable_maps = Redcap2omop::RedcapVariableMap.joins(:concept, :redcap_variable).by_redcap_dictionary(redcap_data_dictionary)
      log_message("Found #{redcap_variable_maps.size} domain redcap_variable_maps")
      redcap_variable_choice_maps = Redcap2omop::RedcapVariableChoiceMap.by_redcap_dictionary(redcap_data_dictionary).not_no_matching_concept
      log_message("Found #{redcap_variable_choice_maps.size} domain redcap_variable_choice_maps")

      redcap_records.each do |redcap_record|
        person_source_value = redcap_record[person_redcap2omop_map['person_source_value']]
        person = Redcap2omop::Person.where(person_source_value: person_source_value).first
        if person.blank?
          log_error("Could not locate person with person_source_value #{person_source_value}")
        else

          redcap_variable_choice_maps.each do |redcap_variable_choice_map|
            redcap_variable = redcap_variable_choice_map.redcap_variable_choice.redcap_variable
            if redcap_record[redcap_variable_choice_map.redcap_variable_choice.redcap_variable_name].present?
              filter_out = redcap_project.complete_instrument && redcap_record["#{redcap_variable.form_name}_complete"].to_i != Redcap2omop::RedcapDataDictionary::INSTRUMENT_COMPLETE_STATUS
              if filter_out
                log_message("Filtering out #{redcap_variable_choice_map.redcap_variable_choice.choice_description} for person with source value #{person_source_value}")
              else
                if redcap_variable_choice_map.redcap_variable_choice.match?(redcap_record[redcap_variable_choice_map.redcap_variable_choice.redcap_variable_name])
                  log_message("Recording #{redcap_variable_choice_map.redcap_variable_choice.choice_description} for person with source value #{person_source_value}")
                  klass = get_omop_domain_from_redcap_variable_choice_map(redcap_variable_choice_map)
                  case klass.to_s
                  when Redcap2omop::Death.to_s
                    klass_instance = Redcap2omop::Death.where(person_id: person.person_id).first
                    if klass_instance.blank?
                      klass_instance = Redcap2omop::Death.new(
                          person_id:          person.person_id,
                          death_type_concept_id: redcap_variable_choice_map.concept.concept_id,
                      )
                    else
                      klass_instance.death_type_concept_id = redcap_variable_map.concept.concept_id
                    end
                  else
                    klass_instance = klass.new(
                      instance_id:        klass.next_id,
                      person_id:          person.person_id,
                      concept_id:         redcap_variable_choice_map.concept.concept_id,
                      type_concept_id:    Redcap2omop::RedcapProject.first.type_concept.concept_id,
                      source_value:       redcap_variable.name
                    )
                  end

                  # Set linked values
                  redcap_variable_choice_map.redcap_variable_choice.redcap_variable_child_maps.each do |redcap_variable_child_map|
                    case redcap_variable_child_map.map_type
                    when Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE
                      redcap_variable_child = redcap_variable_child_map.redcap_variable
                      if redcap_variable_child.choice?
                        value = redcap_variable_child.map_redcap_variable_choice_to_concept(redcap_record)
                        if value.blank?
                          other_redcap_record = redcap_records.select{|record| record['redcap_event_name'] == redcap_record['redcap_event_name'] && record['redcap_repeat_instrument'].blank?}.first
                          value = redcap_variable_child.map_redcap_variable_choice_to_concept(other_redcap_record) if other_redcap_record
                        end
                      else
                        if redcap_record[redcap_variable_child.name].present?
                          source_value = redcap_record[redcap_variable_child.name]
                        else
                          other_redcap_record = redcap_records.select{|record| record['redcap_event_name'] == redcap_record['redcap_event_name'] && record['redcap_repeat_instrument'].blank?}.first
                          source_value = other_redcap_record[redcap_variable_child.name] if other_redcap_record
                        end
                        if source_value && redcap_variable_child_map.omop_column.name == 'provider_id'
                          value = Redcap2omop::Provider.where(provider_source_value: source_value).first.provider_id
                        else
                          value = source_value
                        end
                      end
                    when Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT
                      value = redcap_variable_child_map.concept.concept_id
                    when Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE
                      value = get_redcap_derived_date(redcap_variable_child_map.redcap_derived_date, redcap_record, redcap_records)
                    end
                    klass_instance.write_attribute(redcap_variable_child_map.omop_column.name, value) if value && klass_instance.respond_to?(redcap_variable_child_map.omop_column.name.to_sym)
                  end

                  # Link to source record
                  klass_instance.build_redcap_source_link(redcap_source: redcap_variable)
                  # Do not save with a bang.  If we cannot save becuase we can't map, we want to move on.
                  klass_instance.save
                end
              end
            end
          end

          redcap_variable_maps.each do |redcap_variable_map|
            redcap_variable = redcap_variable_map.redcap_variable
            if redcap_record[redcap_variable.name].present?
              filter_out = redcap_project.complete_instrument && redcap_record["#{redcap_variable_map.redcap_variable.form_name}_complete"].to_i != Redcap2omop::RedcapDataDictionary::INSTRUMENT_COMPLETE_STATUS
              if filter_out
                log_message("Filtering out #{redcap_variable.name} for person with source value #{person_source_value}")
              else
                log_message("Recording #{redcap_variable.name} for person with source value #{person_source_value}")
                klass = get_omop_domain(redcap_variable_map)
                case klass.to_s
                when Redcap2omop::Death.to_s
                  klass_instance = Redcap2omop::Death.where(person_id: person.person_id).first
                  if klass_instance.blank?
                    klass_instance = Redcap2omop::Death.new(
                        person_id:          person.person_id,
                        death_type_concept_id: redcap_variable_map.concept.concept_id
                    )
                  else
                    klass_instance.death_type_concept_id = redcap_variable_map.concept.concept_id
                  end
                else
                  klass_instance = klass.new(
                    instance_id:        klass.next_id,
                    person_id:          person.person_id,
                    concept_id:         redcap_variable_map.concept.concept_id,
                    type_concept_id:    Redcap2omop::RedcapProject.first.type_concept.concept_id,
                    source_value:       redcap_variable.name
                  )
                end

                if klass_instance.respond_to?('value_source_value')
                  klass_instance.value_source_value =  redcap_record[redcap_variable.name]
                  # Set values
                  case redcap_variable.determine_field_type
                  when 'number', 'integer'
                    value_as_concept_id = redcap_variable.map_redcap_variable_choice_to_concept(redcap_record)
                    if value_as_concept_id.present?
                      klass_instance.value_as_concept_id = value_as_concept_id
                    else
                      klass_instance.value_as_number = redcap_record[redcap_variable.name].to_d
                    end
                  when 'choice'
                    klass_instance.value_as_concept_id = redcap_variable.map_redcap_variable_choice_to_concept(redcap_record)
                  when 'text'
                    klass_instance.value_as_string = redcap_record[redcap_variable.name] if klass_instance.respond_to?(:value_as_string)
                  end
                end

                # Set linked values
                redcap_variable.redcap_variable_child_maps.each do |redcap_variable_child_map|
                  case redcap_variable_child_map.map_type
                  when Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_VARIABLE
                    redcap_variable_child = redcap_variable_child_map.redcap_variable
                    if redcap_variable_child.choice?
                      value = redcap_variable_child.map_redcap_variable_choice_to_concept(redcap_record)
                      if value.blank?
                        other_redcap_record = redcap_records.select{|record| record['redcap_event_name'] == redcap_record['redcap_event_name'] && record['redcap_repeat_instrument'].blank?}.first
                        value = redcap_variable_child.map_redcap_variable_choice_to_concept(other_redcap_record) if other_redcap_record
                      end
                    else
                      if redcap_record[redcap_variable_child.name].present?
                        source_value = redcap_record[redcap_variable_child.name]
                      else
                        other_redcap_record = redcap_records.select{|record| record['redcap_event_name'] == redcap_record['redcap_event_name'] && record['redcap_repeat_instrument'].blank?}.first
                        source_value = other_redcap_record[redcap_variable_child.name] if other_redcap_record
                      end
                      if source_value && redcap_variable_child_map.omop_column.name == 'provider_id'
                        value = Redcap2omop::Provider.where(provider_source_value: source_value).first.provider_id
                      else
                        value = source_value
                      end
                    end
                  when Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_OMOP_CONCEPT
                    value = redcap_variable_child_map.concept.concept_id
                  when Redcap2omop::RedcapVariableChildMap::REDCAP_VARIABLE_CHILD_MAP_MAP_TYPE_REDCAP_DERIVED_DATE
                    value = get_redcap_derived_date(redcap_variable_child_map.redcap_derived_date, redcap_record, redcap_records)
                  end
                  klass_instance.write_attribute(redcap_variable_child_map.omop_column.name, value) if value && klass_instance.respond_to?(redcap_variable_child_map.omop_column.name.to_sym)
                end

                # Link to source record
                klass_instance.build_redcap_source_link(redcap_source: redcap_variable)
                # Do not save with a bang.  If we cannot save becuase we can't map, we want to move on.
                klass_instance.save
              end
            end
          end
        end
      end
    end

    def get_omop_domain(redcap_variable_map)
      if redcap_project.route_to_observation || %w[Observation Metadata].include?(redcap_variable_map.concept.domain_id)
        klass = Redcap2omop::Observation
      elsif redcap_variable_map.concept.domain_id == 'Measurement'
        klass = Redcap2omop::Measurement
      elsif redcap_variable_map.concept.domain_id == 'Condition'
        klass = Redcap2omop::ConditionOccurrence
      elsif redcap_variable_map.concept.domain_id == 'Device'
        klass = Redcap2omop::DeiceExposure
      elsif redcap_variable_map.concept.domain_id == 'Drug'
        klass = Redcap2omop::DrugExposure
      elsif redcap_variable_map.concept.domain_id == 'Procedure'
        klass = Redcap2omop::ProcedureOccurrence
      elsif redcap_variable_map.concept.domain_id == 'Visit'
        klass = Redcap2omop::VisitOccurrence
      elsif redcap_variable_map.concept.vocabulary_id == 'Death Type'
        klass = Redcap2omop::Death
      end
      klass
    end

    def get_omop_domain_from_redcap_variable_choice_map(redcap_variable_choice_map)
      if redcap_project.route_to_observation || %w[Observation Metadata].include?(redcap_variable_choice_map.concept.domain_id)
        klass = Redcap2omop::Observation
      elsif redcap_variable_choice_map.concept.domain_id == 'Measurement'
        klass = Redcap2omop::Measurement
      elsif redcap_variable_choice_map.concept.domain_id == 'Condition'
        klass = Redcap2omop::ConditionOccurrence
      elsif redcap_variable_choice_map.concept.domain_id == 'Device'
        klass = Redcap2omop::DeviceExposure
      elsif redcap_variable_choice_map.concept.domain_id == 'Drug'
        klass = Redcap2omop::DrugExposure
      elsif redcap_variable_choice_map.concept.domain_id == 'Procedure'
        klass = Redcap2omop::ProcedureOccurrence
      elsif redcap_variable_choice_map.concept.domain_id == 'Visit'
        klass = Redcap2omop::VisitOccurrence
      elsif redcap_variable_map.concept.vocabulary_id == 'Death Type'
        klass = Redcap2omop::Death
      end
      klass
    end

    def log_message(message)
      logger.info "[#{log_prefix}]: #{message}"
    end

    def log_error(message)
      logger.error "[#{log_prefix}]: #{message}"
    end

    def log_prefix
      'RedcapToOmop'
    end

    def get_redcap_derived_date(redcap_derived_date, redcap_record, redcap_records)
      if redcap_derived_date.base_date_redcap_variable.present?
        if redcap_record[redcap_derived_date.base_date_redcap_variable.name].present?
          base_date = Date.parse(redcap_record[redcap_derived_date.base_date_redcap_variable.name])
        else
          other_redcap_record = redcap_records.select{|record| record['redcap_event_name'] == redcap_record['redcap_event_name'] && record['redcap_repeat_instrument'].blank?}.first
          base_date = Date.parse(other_redcap_record[redcap_derived_date.base_date_redcap_variable.name]) if other_redcap_record
        end

        if redcap_record[redcap_derived_date.offset_redcap_variable.name].present?
          offset_choice_code_raw = redcap_record[redcap_derived_date.offset_redcap_variable.name]
          redcap_variable_choice = redcap_derived_date.offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice| redcap_variable_choice.choice_code_raw == offset_choice_code_raw }
          if redcap_variable_choice.present?
            redcap_derived_date_choice_offset_mapping = redcap_derived_date.redcap_derived_date_choice_offset_mappings.detect { |redcap_derived_date_choice_offset_mapping| redcap_derived_date_choice_offset_mapping.redcap_variable_choice_id == redcap_variable_choice.id }
          end
        else
          other_redcap_record = redcap_records.select{|record| record['redcap_event_name'] == redcap_record['redcap_event_name'] && record['redcap_repeat_instrument'].blank?}.first

          offset_choice_code_raw = other_redcap_record[redcap_derived_date.offset_redcap_variable.name]
          redcap_variable_choice = redcap_derived_date.offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice| redcap_variable_choice.choice_code_raw == offset_choice_code_raw }
          if redcap_variable_choice.present?
            redcap_derived_date_choice_offset_mapping = redcap_derived_date.redcap_derived_date_choice_offset_mappings.detect { |redcap_derived_date_choice_offset_mapping| redcap_derived_date_choice_offset_mapping.redcap_variable_choice_id == redcap_variable_choice.id }
          end
        end

        if base_date.present? && redcap_derived_date_choice_offset_mapping.present?
          value = (base_date - redcap_derived_date_choice_offset_mapping.offset_days)
        else
          value = nil
        end
      elsif redcap_derived_date.parent_redcap_derived_date.present?
        offset_days = nil
        if redcap_record[redcap_derived_date.offset_redcap_variable.name].present?
          if redcap_derived_date.offset_redcap_variable.choice?
            offset_choice_code_raw = redcap_record[redcap_derived_date.offset_redcap_variable.name]
            redcap_variable_choice = redcap_derived_date.offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice| redcap_variable_choice.choice_code_raw == offset_choice_code_raw }
            if redcap_variable_choice.present?
              redcap_derived_date_choice_offset_mapping = redcap_derived_date.redcap_derived_date_choice_offset_mappings.detect { |redcap_derived_date_choice_offset_mapping| redcap_derived_date_choice_offset_mapping.redcap_variable_choice_id == redcap_variable_choice.id }
              if redcap_derived_date_choice_offset_mapping.present?
                offset_days = redcap_derived_date_choice_offset_mapping.offset_days
              end
            end
          else
            case redcap_derived_date.offset_interval_direction
            when Redcap2omop::RedcapDerivedDate::OFFSET_INTERVAL_DIRECTION_PAST
              direction = -1
            when Redcap2omop::RedcapDerivedDate::OFFSET_INTERVAL_DIRECTION_FUTURE
              direction = 1
            end
            offset_days = redcap_record[redcap_derived_date.offset_redcap_variable.name].to_i * redcap_derived_date.offset_interval_days * direction
          end
        else
          other_redcap_record = redcap_records.select{|record| record['redcap_event_name'] == redcap_record['redcap_event_name'] && record['redcap_repeat_instrument'].blank?}.first
          if redcap_derived_date.offset_redcap_variable.field_type_normalized.choice?
            offset_choice_code_raw = other_redcap_record[redcap_derived_date.offset_redcap_variable.name]
            redcap_variable_choice = redcap_derived_date.offset_redcap_variable.redcap_variable_choices.detect { |redcap_variable_choice| redcap_variable_choice.choice_code_raw == offset_choice_code_raw }
            if redcap_variable_choice.present?
              redcap_derived_date_choice_offset_mapping = redcap_derived_date.redcap_derived_date_choice_offset_mappings.detect { |redcap_derived_date_choice_offset_mapping| redcap_derived_date_choice_offset_mapping.redcap_variable_choice_id == redcap_variable_choice.id }
              offset_days = redcap_derived_date_choice_offset_mapping.offset_days
            end
          else
            case redcap_derived_date.offset_interval_direction
            when Redcap2omop::RedcapDerivedDate::OFFSET_INTERVAL_DIRECTION_PAST
              direction = -1
            when Redcap2omop::RedcapDerivedDate::OFFSET_INTERVAL_DIRECTION_FUTURE
              direction = 1
            end
            offset_days = redcap_record[redcap_derived_date.offset_redcap_variable.name].to_i * redcap_derived_date.offset_interval_days * direction
          end
        end

        base_date = get_redcap_derived_date(redcap_derived_date.parent_redcap_derived_date, redcap_record, redcap_records)

        if offset_days.present? && base_date.present?
          value = (base_date - offset_days)
        else
          value = nil
        end
      end
      value
    end
  end
end