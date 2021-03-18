module Redcap2omop
  class Observation < ApplicationRecord
    include Redcap2omop::Methods::Models::Observation
  end
end
