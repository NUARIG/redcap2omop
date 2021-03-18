module Redcap2omop
  class RedcapDataDictionary < ApplicationRecord
    include Redcap2omop::Methods::Models::RedcapDataDictionary
  end
end
