module Redcap2omop::SoftDelete
  extend ActiveSupport::Concern

  included do
    scope :not_deleted, -> { where(:deleted_at => nil) }
    scope :deleted, -> { where('deleted_at IS NOT NULL') }
  end

  def process_soft_delete
    self.deleted_at = Time.zone.now
  end

  def soft_delete=(removed)
    if (removed.is_a?(TrueClass) || removed.to_s == 't' || removed.to_s == '1')
      process_soft_delete
    end
  end

  def soft_delete!
    process_soft_delete
    save!
  end

  def deleted?
    !deleted_at.blank?
  end
end
