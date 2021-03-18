module Redcap2omop::Methods::Models::RedcapVariable
  def self.included(base)
    base.send :include, Redcap2omop::SoftDelete

    # Associations
    base.send :belongs_to, :redcap_data_dictionary
    base.send :has_many, :redcap_variable_choices
    base.send :has_many, :redcap_variable_maps
    base.send :has_many, :redcap_variable_child_maps, as: :parentable
    base.send :has_many, :redcap_source_links, as: :redcap_source

    # Hooks
    base.send :before_validation, :normalize_field_type, :set_variable_choices

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
    def normalize_field_type
      field_type =  case self.field_type
                    when 'radio', 'checkbox', 'dropdown'
                      'choice'
                    when 'slider'
                      'integer'
                    when 'text'
                      case self.text_validation_type
                      when 'date_ymd'
                        'date'
                      when 'integer'
                        'integer'
                      else
                        'text'
                      end
                    else
                      self.field_type
                    end
      self.field_type_normalized = field_type
    end

    def choice?
      self.field_type_normalized == 'choice' && self.field_type_curated != 'integer'
    end

    def checkbox?
      self.field_type == 'checkbox' && self.field_type_curated != 'integer'
    end

    def integer?
      self.field_type_normalized == 'integer' || self.field_type_curated == 'integer'
    end

    def map_redcap_variable_choice_to_concept(redcap_record)
      if self.checkbox?
        mapped_choices = []
        self.redcap_variable_choices.each do |redcap_variable_choice|
          mapped_choices << {
            chosen: redcap_record["#{self.name}___#{redcap_variable_choice.choice_code_raw}"],
            redcap_choice_code: redcap_variable_choice.choice_code_raw,
            omop_concept_id: redcap_variable_choice.redcap_variable_choice_map.concept_id
          }
        end
        mapped_choice = mapped_choices.detect { |mapped_choice| mapped_choice[:chosen] == '1' }
        mapped_choice[:omop_concept_id] if mapped_choice
      elsif self.choice? || self.integer?
        redcap_variable_choice = self.redcap_variable_choices.where(choice_code_raw: redcap_record[self.name]).first
        if redcap_variable_choice && redcap_variable_choice.redcap_variable_choice_map
          redcap_variable_choice.redcap_variable_choice_map.concept_id
        end
      end
    end

    def determine_field_type
      if self.field_type_curated
        self.field_type_curated
      else
        self.field_type_normalized
      end
    end

    def set_variable_choices
      return if self.choices.blank? || self.redcap_variable_choices.any?
      self.choices.split('|').each_with_index do |choice, i|
        choice_code, delimiter, choice_description = choice.partition(',')
        self.redcap_variable_choices.build(
          choice_code_raw:    choice_code.try(:strip),
          choice_description: choice_description.try(:strip),
          vocabulary_id_raw:  self.field_annotation.try(:strip),
          ordinal_position:   i,
          curated:            false
        )
      end
    end
  end

  module ClassMethods
    def get_by_name(name)
      where(name: name).first
    end
  end
end
