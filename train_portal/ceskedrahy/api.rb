module TrainPortal::CeskeDrahy
  module API
    module_function
    extend TrainPortal::API
    WIFI_SSID = 'CDWiFi'
    def default_base_url = 'http://cdwifi.cz'
    def cd_wifi? = WIFI_SSID == current_ssid
    def media = [Audiobooks, Books, Music, Movies]

    def active?
      Nokogiri::HTML(get('/')).css('title').text == 'On Board Portal' || cd_wifi?
    rescue
      false
    end
  end
end
