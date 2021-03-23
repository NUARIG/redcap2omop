module Redcap2omop
  class RedcapEvent < ApplicationRecord
    include Redcap2omop::Methods::Models::RedcapEvent
  end
end
