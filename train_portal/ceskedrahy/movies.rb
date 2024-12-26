module TrainPortal::CeskeDrahy
  module Movies
    module_function
    def title = '🍿 Movies'

    def all
      @@all ||= API.get_json('/portal/api/movie?locale=en_GB&amount=500').sort_by { |book| book['title'] }
    end

    def select_hash
      options = all.map.with_index do |movie, index|
        title = movie['title']
        infos = []
        infos << movie['year'] if movie['year']
        infos << movie['country'] if movie['country']
        infos << "Audio: #{movie['audioLanguage']}"
        infos << "Original title: #{movie['originalTitle']}" if movie['title'] != movie['originalTitle']
        title << " (#{infos.join(', ')})" unless infos.empty?
        [title, index]
      end
      options.to_h
    end

    def download(base_json)
      puts 'not implemented yet. Sorry'
      exit 1
    end
  end
end
