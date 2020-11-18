class RedcapVariable < ApplicationRecord
  include SoftDelete
  belongs_to :redcap_data_dictionary
  has_many :redcap_variable_choices
  has_many :redcap_variable_maps
  has_many :redcap_variable_child_maps, as: :parentable

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
    self.field_type_normalized == 'choice'
  end

  def checkbox?
    self.field_type == 'checkbox'
  end

  def map_redcap_variable_choice(redcap_export_tmp)
    if self.checkbox?
      mapped_choices = []
      self.redcap_variable_choices.each do |redcap_variable_choice|
        mapped_choices << { chosen: redcap_export_tmp["#{self.name}___#{}#{redcap_variable_choice.choice_code_raw}"], redcap_choice_code: redcap_variable_choice.choice_code_raw, omop_concept_id: redcap_variable_choice.redcap_variable_choice_map.concept_id }
      end
      mapped_choice = mapped_choices.detect { |mapped_choice| mapped_choice[:chosen] == '1' }
      mapped_choice[:omop_concept_id]
    elsif self.choice?
      redcap_variable_choice = self.redcap_variable_choices.where(choice_code_raw: redcap_export_tmp[self.name]).first
      redcap_variable_choice.redcap_variable_choice_map.concept_id
    end
  end
end
