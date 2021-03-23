module Redcap2omop
  class Person < ApplicationRecord
    include Redcap2omop::Methods::Models::Person
  end
end
