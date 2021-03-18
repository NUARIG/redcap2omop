module Redcap2omop
  class Provider < ApplicationRecord
    include Redcap2omop::Methods::Models::Provider
  end
end
