module TrainPortal::CeskeDrahy
  module Audiobooks
    module_function
    def title = '🎧 Audiobooks'

    def all
      @@all ||= API.get_json('/portal/api/audiobook?locale=en_GB&amount=500').sort_by { |book| book['title'] }
    end

    def select_hash
      all.map.with_index { |book, index| [book['title'], index] }.to_h
    end

    def download(base_json)
      puts 'not implemented yet. Sorry'
      exit 1
    end
  end
end
