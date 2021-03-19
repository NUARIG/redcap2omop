class RedcapVariableChoice < ApplicationRecord
  include SoftDelete
  belongs_to :redcap_variable
  has_one :redcap_variable_choice_map
  has_many :redcap_variable_child_maps, as: :parentable

  REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED = 'undetermined'
  REDCAP_VARIABLE_CHOICE_CURATION_STATUS_SKIPPED = 'skipped'
  REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED = 'mapped'
  REDCAP_VARIABLE_CHOICE_CURATION_STATUSES = [REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED, REDCAP_VARIABLE_CHOICE_CURATION_STATUS_SKIPPED, REDCAP_VARIABLE_CHOICE_CURATION_STATUS_MAPPED]

  after_initialize :set_defaults

  def redcap_variable_name
    if redcap_variable.checkbox?
      "#{redcap_variable.name}___#{self.choice_code_raw}"
    else
      redcap_variable.name
    end
  end

  def match?(value)
    if redcap_variable.checkbox?
      value == '1'
    else
      value == self.choice_code_raw
    end
  end

  private
    def set_defaults
      if self.new_record?
        self.curation_status = RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED
      end
    end
end