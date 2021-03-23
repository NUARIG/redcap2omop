require 'rest_client'

module Redcap2omop::Webservices
  class RedcapApi
    attr_accessor :api_token, :api_url

    def initialize(api_token:)
      @api_token  = api_token
      @api_url    = Rails.application.secrets[:redcap][:api_url]
      @verify_ssl = Rails.application.secrets[:redcap][:verify_ssl] if Rails.env.development? || Rails.env.test?
      @verify_ssl ||= true
    end

    def project
      response = nil
      parameters = {
        token: @api_token,
        content: 'project',
        format: 'json',
        returnFormat: 'json'
      }
      api_response = redcap_api_request_wrapper(parameters)
      api_response
    end

    def metadata
      response = nil
      parameters = {
        token: @api_token,
        content: 'project',
        format: 'json',
        returnFormat: 'json'
      }
      api_response = redcap_api_request_wrapper(parameters)
      api_response
    end

    def records
      response = nil
      parameters = {
        token: @api_token,
        content: 'record',
        format: 'json',
        returnFormat: 'json',
        type: 'flat'
        # csvDelimiter:
        # rawOrLabel: raw
        # rawOrLabelHeaders: raw
        # exportCheckboxLabel: false
        # exportSurveyFields: false
        # exportDataAccessGroups: false
        # returnFormat: json
      }
      api_response = redcap_api_request_wrapper(parameters)
      api_response
    end

    def export_field_names
      response = nil
      parameters = {
        token: @api_token,
        content: 'exportFieldNames',
        format: 'json',
        returnFormat: 'json',
      }
      api_response = redcap_api_request_wrapper(parameters)
      api_response
    end

    def instruments
      response = nil
      parameters = {
        token: @api_token,
        content: 'instrument',
        format: 'json',
        returnFormat: 'json'
      }
      api_response = redcap_api_request_wrapper(parameters)
      api_response
    end

    def events
      response = nil
      parameters = {
        token: @api_token,
        content: 'event',
        format: 'json',
        returnFormat: 'json'
      }
      api_response = redcap_api_request_wrapper(parameters)
      api_response
    end

    def metadata
      response = nil
      parameters = {
        token: @api_token,
        content: 'metadata',
        format: 'json',
        returnFormat: 'json'
      }
      api_response = redcap_api_request_wrapper(parameters)
      api_response
    end

    def redcap_api_request(options, parse_response = true)
      payload = {
        token: @api_token
      }
      return redcap_api_request_wrapper(payload.merge!(options), parse_response)
    end

    private

    def redcap_api_request_wrapper(payload, parse_response = true)
      response = nil
      error =  nil
      begin
        response = RestClient::Request.execute(
          method: :post,
          url: @api_url,
          payload: payload,
          content_type:  'application/json',
          accept: 'json',
          verify_ssl: @verify_ssl
        )
        response = JSON.parse(response) if parse_response
      rescue Exception => e
        error = e
        Rails.logger.info(e.message)
        Rails.logger.info(e.class)
      end
      { response: response, error: error }
    end
  end
end
