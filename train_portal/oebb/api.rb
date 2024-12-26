# frozen_string_literal: true

require 'addressable/uri'

module TrainPortal::Oebb
  module API
    module_function
    extend TrainPortal::API

    def active?
      response = get('/', full_response: true)
      response.code == '200' && response.body.include?('ÖBB Railnet')
    end

    def default_base_url = 'https://railnet.oebb.at'
  end
end
