module IcePortal
  module Magazines
    module_function
    DOWNLOAD_PATH = File.expand_path('./magazines')

    def all
      API.get_json('/api1/rs/page/zeitungskiosk')['teaserGroups'].first['items'].select do |magazine|
        magazine.dig('picture', 'marker', 'text') == 'Freies Exemplar'
      end
    end

    def download(base_json)
      details = API.get_json("/api1/rs/page/#{base_json.dig('navigation', 'href')}")
      return if details['paymethod'] == 'paymentProvider'
      # slug = base_json['navigation']['href'].split('/').last
      edition = base_json['picture']['src'].split('/').last.sub(/\.\w+\z/, '')
      slug = "#{base_json['title']}_#{edition}".gsub(/\W+/, '_')
      directory = File.join(DOWNLOAD_PATH, base_json['title'].gsub(/\W+/, '_'))

      API.file_download("/#{details['url']}", File.join(DOWNLOAD_PATH, "#{slug}.pdf"))
    end
  end
end
