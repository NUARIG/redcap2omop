class Person < ApplicationRecord
  self.table_name = 'person'
  self.primary_key = 'person_id'

  before_save :set_birth_fields

  def self.next_person_id
    person_id = Person.maximum(:person_id)
    if person_id.nil?
      person_id = 1
    else
      person_id+=1
    end
    person_id
  end

  def set_birth_fields
    if self.birth_datetime.present?
      self.year_of_birth =   self.birth_datetime.year
      self.month_of_birth =   self.birth_datetime.month
      self.day_of_birth =   self.birth_datetime.day
    end
  end
end