class RedcapVariable < ApplicationRecord
  include SoftDelete
  belongs_to :redcap_data_dictionary
  has_many :redcap_variable_choices
  has_many :redcap_variable_maps
  has_many :redcap_variable_child_maps, as: :parentable

  def normalize_field_type
    normalized_field_type = case self.field_type
    when 'radio', 'radio', 'slider', 'checkbox'
      'choice'
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
end