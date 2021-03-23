module Redcap2omop::WithNextId
  extend ActiveSupport::Concern

  included do
    after_initialize  :set_next_id
    before_validation :set_next_id

    def set_next_id
      if self.class.sequence_name.blank? && self.send(self.class.primary_key).blank?
        self.send("#{self.class.primary_key}=", self.class.next_id)
      end
    end
  end

  class_methods do
    def next_id
      max_id = self.maximum(self.primary_key)
      max_id ||= 0
      max_id + 1
    end
  end
end
