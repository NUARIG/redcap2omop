module Redcap2omop
  class Engine < ::Rails::Engine
    isolate_namespace Redcap2omop

    root = File.expand_path('../../', __FILE__)
    config.autoload_paths << root

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end
  end
end
