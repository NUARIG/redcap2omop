module WithNextId
  extend ActiveSupport::Concern

  class_methods do
    def next_id
      max_id = self.maximum(self.primary_key)
      max_id ||= 0
      max_id + 1
    end
  end
end
