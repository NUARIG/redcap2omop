

module Redcap2omop::Methods::Models::RedcapDataDictionary
  INSTRUMENT_INCOMPLETE_STATUS = 0.freeze
  INSTRUMENT_UNVERIFIED_STATUS = 1.freeze
  INSTRUMENT_COMPLETE_STATUS   = 2.freeze

  def self.included(base)
    base.send :include, Redcap2omop::SoftDelete

    # Associations
    base.send :belongs_to, :redcap_project
    base.send :has_many, :redcap_events
    base.send :has_many, :redcap_variables

    # Hooks
    base.send :before_validation, :set_version, if: :new_record?

    base.send :include, InstanceMethods
    base.extend(ClassMethods)
  end

  module InstanceMethods
    private
      def set_version
        self.version = previous_version + 1
      end

      def previous_version
        previous_record && previous_record.version ? previous_record.version : 0
      end

      def previous_record
        if redcap_project.blank?
          nil
        elsif self.id?
          redcap_project.redcap_data_dictionaries.where('id < ?', self.id).last
        else
          redcap_project.redcap_data_dictionaries.last
        end
      end
  end

  module ClassMethods
  end
end
