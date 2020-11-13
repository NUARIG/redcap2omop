class OmopColumn < ApplicationRecord
  include SoftDelete
  belongs_to :omop_table
end