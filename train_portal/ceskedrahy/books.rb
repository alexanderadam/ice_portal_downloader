module TrainPortal::CeskeDrahy
  module Books
    module_function
    def title = '📚 Books'
    def all
      @@all ||= API.get_json('/portal/api/book?locale=en_GB&amount=500').sort_by { |book| book['title'] }
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
