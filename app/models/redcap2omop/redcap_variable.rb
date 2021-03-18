module Redcap2omop
  class RedcapVariable < ApplicationRecord
    include Redcap2omop::Methods::Models::RedcapVariable
  end
end
