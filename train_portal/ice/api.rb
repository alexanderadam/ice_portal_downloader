# frozen_string_literal: true

require 'addressable/uri'

module TrainPortal::Ice
  module API
    module_function
    extend TrainPortal::API
    ICE_WIFI_SSIDs = %w[WIFIonICE]

    def active?
      !get('/').include?('"Bitte mit dem WLAN im Zug verbinden"') || ice_wifi?
    rescue
      false
    end

    def default_base_url = 'https://iceportal.de'
    def media = [Magazines, Audiobooks]
    def ice_wifi? = ICE_WIFI_SSIDs.include?(current_ssid)
  end
end
