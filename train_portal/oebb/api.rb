# frozen_string_literal: true

require 'addressable/uri'

module TrainPortal::Oebb
  module API
    module_function
    extend TrainPortal::API
    def default_base_url = 'https://railnet.oebb.at'

    def active?
      response = get('/', full_response: true)
      response.code == '200' && response.body.include?('ÖBB Railnet')
    end
  end
end
