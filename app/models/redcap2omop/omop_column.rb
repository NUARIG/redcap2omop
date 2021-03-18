module Redcap2omop
  class OmopColumn < ApplicationRecord
    include Redcap2omop::Methods::Models::OmopColumn
  end
end
