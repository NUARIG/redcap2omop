class Person < ApplicationRecord
  include WithNextId

  self.table_name = 'person'
  self.primary_key = 'person_id'

  validates_presence_of :gender_concept_id, :year_of_birth, :race_concept_id, :ethnicity_concept_id

  before_validation :set_birth_fields

  def set_birth_fields
    if self.birth_datetime.present?
      self.year_of_birth  = self.birth_datetime.year
      self.month_of_birth = self.birth_datetime.month
      self.day_of_birth   = self.birth_datetime.day
    end
  end
end
