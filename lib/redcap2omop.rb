require "redcap2omop/version"
require "redcap2omop/engine"
require "redcap2omop/setup/setup"
require "redcap2omop/webservices/redcap_api"
require 'american_date'
require 'webpacker'
require 'hotwire-rails'

module Redcap2omop
  class << self
    def webpacker
      @webpacker ||= ::Webpacker::Instance.new(
        root_path: Redcap2omop::Engine.root,
        config_path: Redcap2omop::Engine.root.join('config', 'webpacker.yml')
      )
    end
  end
end
