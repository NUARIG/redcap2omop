class OmopTable < ApplicationRecord
  include SoftDelete
  has_many :omop_columns
end