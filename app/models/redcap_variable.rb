class RedcapVariable < ApplicationRecord
  include SoftDelete
  belongs_to :redcap_data_dictionary
  has_many :redcap_variable_choices
  has_many :redcap_variable_maps
  has_many :redcap_variable_child_maps, as: :parentable
  has_many :redcap_source_links, as: :redcap_source

  def normalize_field_type
    normalized_field_type = case self.field_type
    when 'radio', 'radio', 'checkbox', 'dropdown'
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
  end

  def choice?
    self.field_type_normalized == 'choice' && self.field_type_curated != 'integer'
  end

  def checkbox?
    self.field_type == 'checkbox' && self.field_type_curated != 'integer'
  end

  def integer?
    self.field_type_curated == 'integer'  || self.field_type_normalized == 'integer'
  end

  def map_redcap_variable_choice(redcap_export_tmp)
    if self.checkbox?
      mapped_choices = []
      self.redcap_variable_choices.each do |redcap_variable_choice|
        mapped_choices << { chosen: redcap_export_tmp["#{self.name}___#{}#{redcap_variable_choice.choice_code_raw}"], redcap_choice_code: redcap_variable_choice.choice_code_raw, omop_concept_id: redcap_variable_choice.redcap_variable_choice_map.concept_id }
      end
      mapped_choice = mapped_choices.detect { |mapped_choice| mapped_choice[:chosen] == '1' }
      if mapped_choice
        mapped_choice[:omop_concept_id]
      end
    elsif self.choice?
      redcap_variable_choice = self.redcap_variable_choices.where(choice_code_raw: redcap_export_tmp[self.name]).first
      if redcap_variable_choice.present?
        redcap_variable_choice.redcap_variable_choice_map.concept_id
      end
    elsif self.integer?
      redcap_variable_choice = self.redcap_variable_choices.where(choice_code_raw: redcap_export_tmp[self.name]).first
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
end
