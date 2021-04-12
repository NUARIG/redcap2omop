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

    initializer "webpacker.proxy" do |app|
      insert_middleware = begin
                            Redcap2omop.webpacker.config.dev_server.present?
                          rescue
                            nil
                          end
      next unless insert_middleware

      app.middleware.insert_before(
        0, Webpacker::DevServerProxy, # "Webpacker::DevServerProxy" if Rails version < 5
        ssl_verify_none: true,
        webpacker: Redcap2omop.webpacker
      )
    end

    config.app_middleware.use(
      Rack::Static,
      urls: ["/redcap2omop-packs"], root: Redcap2omop::Engine.root.join("public")
    )
  end
end
