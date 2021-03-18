module Redcap2omop
  class RedcapProject < ApplicationRecord
    include Redcap2omop::Methods::Models::RedcapProject
  end
end
