require 'rails_helper'
require 'support/shared_examples/with_next_id'
module Redcap2omop
  RSpec.describe Provider, type: :model do
    let(:provider) { FactoryBot.create(:provider) }
    let(:subject)  { provider }

    include_examples 'with next_id'
  end
end
