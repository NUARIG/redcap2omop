class RedcapDataDictionary < ApplicationRecord
  include SoftDelete
  belongs_to  :redcap_project
  has_many    :redcap_events
  has_many    :redcap_variables

  INSTRUMENT_INCOMPLETE_STATUS = 0.freeze
  INSTRUMENT_UNVERIFIED_STATUS = 1.freeze
  INSTRUMENT_COMPLETE_STATUS   = 2.freeze

  after_initialize :set_version, if: :new_record?

  def set_version
    self.version = previous_version + 1
  end

  def previous_version
    previous_record && previous_record.version ? previous_record.version : 0
  end

  def previous_record
    if self.id?
      redcap_project.redcap_data_dictionaries.where('id < ?', self.id).last
    else
      redcap_project.redcap_data_dictionaries.last
    end
  end
end
