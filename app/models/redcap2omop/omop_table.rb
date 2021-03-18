module Redcap2omop
  class OmopTable < ApplicationRecord
    include Redcap2omop::Methods::Models::OmopTable
  end
end
