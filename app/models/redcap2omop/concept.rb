module Redcap2omop
  class Concept < ApplicationRecord
    include Redcap2omop::Methods::Models::Concept
  end
end
