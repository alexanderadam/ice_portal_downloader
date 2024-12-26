module TrainPortal::Ice
  module Magazines
    module_function

    def title = '📰 Magazines'

    def all
      @@all ||= API.get_json('/api1/rs/page/zeitungskiosk')['teaserGroups']
                   .first['items']
                   .sort_by { |h| h['title'] }
                   .select do |magazine|
        magazine.dig('picture', 'marker', 'text') == 'Freies Exemplar'
      end
    end

    def select_hash
      all.map.with_index { |magazine, index| [magazine['title'], index] }.to_h
    end

    def download(base_json)
      details = API.get_json("/api1/rs/page/#{base_json.dig('navigation', 'href')}")
      return if details['paymethod'] == 'paymentProvider'
      # slug = base_json['navigation']['href'].split('/').last
      edition = base_json['picture']['src'].split('/').last.sub(/\.\w+\z/, '')
      slug = "#{base_json['title']}_#{edition}".gsub(/\W+/, '_')
      sub_directory = self.name.split('::').last

      API.file_download("/#{details['url']}", File.join(sub_directory, "#{slug}.pdf"))
    end
  end
end
