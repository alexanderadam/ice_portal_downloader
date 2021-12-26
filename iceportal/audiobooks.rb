module IcePortal
  module Audiobooks
    module_function

    DOWNLOAD_PATH = File.expand_path('./audiobooks')
    TMP_EXTENSION = '.tmp'
    # you can look up more genres at https://en.wikipedia.org/wiki/List_of_ID3v1_Genres#Extension_by_Winamp
    GENRES = {
      'podcast' => 186,
      'audioBook' => 183
    }.freeze

    def all
      json_data = API.get_json('/api1/rs/page/hoerbuecher')

      json_data['teaserGroups'].first['items'].map do |item|
        item['navigation']
      end
    end

    def update_id3_info(file_path, book_json, chapter_json, cover_path)
      Mp3Info.open(file_path) do |mp3|
        mp3.tag.album = book_json['title']
        mp3.tag.artist = book_json['author']
        mp3.tag.title = chapter_json['title']
        mp3.tag.comments = chapter_json['description']
        mp3.tag.tracknum = chapter_json['serialNumber']
        mp3.tag.genre = GENRES[book_json['contentType']] || raise("Unknown genre #{book_json['contentType']}")
        mp3.tag.year = book_json['releaseYear']
        mp3.tag2.add_picture(File.read(cover_path, mode: 'rb'))
      end
    rescue StandardError => e
      puts "Unable to update ID3 metadata for #{File.basename(file_path)} #{e.class}: #{e.message}"
    end

    def download_track(slug, chapter_json, tmp_dir, track_no)
      download_url = API.get_json("/api1/rs/audiobooks/path#{chapter_json['path']}")['path']

      file_path = File.join(tmp_dir, "#{slug}_#{track_no}.mp3")
      API.file_download download_url, file_path
      file_path
    end

    def download_cover(book_json, tmp_dir)
      cover_image_path = "/#{book_json['picture']['src']}"
      cover_path = File.join(tmp_dir, "cover.#{cover_image_path.split('.').last || 'jpg'}")
      API.file_download cover_image_path, cover_path
      cover_path
    end

    def download(base_json)
      slug = base_json['href'].split('/').last
      directory = File.join(DOWNLOAD_PATH, slug)
      tmp_dir = "#{directory}#{TMP_EXTENSION}" # use .tmp extension unless the audiobook isn't fully downloaded

      if Dir.exist?(directory) # we assume that the audiobook was fully downloaded if the directory exists
        puts "\nAudiobook #{slug}/ already exists"
        return
      end

      FileUtils.mkdir_p(tmp_dir) unless File.directory?(tmp_dir)

      book_json = API.get_json("/api1/rs/page/hoerbuecher/#{slug}")
      cover_path = download_cover(book_json, tmp_dir)

      progress_bar = Support.progress_bar(book_json['title'], book_json['files'].count)

      rjust_params = [book_json['files'].count.to_s.size, '0']

      # iterate over every file of the audiobook / podcast
      book_json['files'].each do |chapter_json|
        track_no = chapter_json['serialNumber'].to_s.rjust(*rjust_params)
        file_path = download_track(slug, chapter_json, tmp_dir, track_no)
        update_id3_info(file_path, book_json, chapter_json, cover_path)
        progress_bar.increment
      end
      File.rename(tmp_dir, directory)
    end
  end
end
