module Redcap2omop
  class Death < ApplicationRecord
    include Redcap2omop::Methods::Models::Death
  end
end
