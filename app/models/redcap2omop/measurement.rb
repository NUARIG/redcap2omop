module Redcap2omop
  class Measurement < ApplicationRecord
    include Redcap2omop::Methods::Models::Measurement
  end
end
