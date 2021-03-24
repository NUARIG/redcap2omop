module Redcap2omop
  module ApplicationHelper
    include ::Webpacker::Helper

    def current_webpacker_instance
      Redcap2omop.webpacker
    end
  end
end
