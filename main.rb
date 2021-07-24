#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'net/http'
require 'open-uri'
require 'ruby-progressbar'
require 'mp3info'

DOWNLOAD_PATH = File.expand_path('./audiobooks')
TMP_EXTENSION = '.tmp'
# you can look up more genres at https://en.wikipedia.org/wiki/List_of_ID3v1_Genres#Extension_by_Winamp
GENRES = {
  'podcast' => 186,
  'audioBook' => 183
}.freeze

# Begin of monkey patch to avoid issue https://github.com/moumar/ruby-mp3info/issues/67
Mp3Info.class_eval do
  ### reads through @io from current pos until it finds a valid MPEG header
  ### returns the MPEG header as FixNum
  def find_next_frame
    # @io will now be sitting at the best guess for where the MPEG frame is.
    # It should be at byte 0 when there's no id3v2 tag.
    # It should be at the end of the id3v2 tag or the zero padding if there
    #   is a id3v2 tag.
    # dummyproof = @io.stat.size - @io.pos => WAS TOO MUCH

    dummyproof = [@io_size - @io.pos, 39_000_000].min
    dummyproof.times do |_i|
      next unless @io.getbyte == 0xff

      data = @io.read(3)
      raise Mp3InfoEOFError if @io.eof?

      head = 0xff000000 + (data.getbyte(0) << 16) + (data.getbyte(1) << 8) + data.getbyte(2)
      begin
        return Mp3Info.get_frames_infos(head)
      rescue Mp3InfoInternalError
        @io.seek(-3, IO::SEEK_CUR)
      end
    end
    if @io.eof?
      raise Mp3InfoEOFError
    else
      raise Mp3InfoError, "cannot find a valid frame after reading #{dummyproof} bytes"
    end
  end
end
# end of monkey patch

def create_folder(directory)
  FileUtils.mkdir_p(directory) unless File.directory?(directory)
end

def get(path)
  Net::HTTP.get(URI("https://iceportal.de#{path}"))
end

def get_json(path)
  JSON.parse(get(path))
end

def download(url_path, file_path)
  File.write file_path, get(url_path), mode: 'wb'
end

def audiobooks
  json_data = get_json('/api1/rs/page/hoerbuecher')

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
  response_download_path = get_json("/api1/rs/audiobooks/path#{chapter_json['path']}")['path']

  file_path = File.join(tmp_dir, "#{slug}_#{track_no}.mp3")
  download(response_download_path, file_path)
  file_path
end

def download_cover(book_json, tmp_dir)
  cover_image_path = "/#{book_json['picture']['src']}"
  cover_path = File.join(tmp_dir, "cover.#{cover_image_path.split('.').last || 'jpg'}")
  download(cover_image_path, cover_path)
  cover_path
end

def download_audiobook(base_json)
  slug = base_json['href'].split('/').last
  directory = File.join(DOWNLOAD_PATH, slug)
  tmp_dir = "#{directory}#{TMP_EXTENSION}" # use .tmp extension unless the audiobook wasn't fully downloaded

  if Dir.exist?(directory) # we assume that the audiobook was fully downloaded if the directory exists
    puts "\nAudiobook #{slug}/ already exists"
    return
  end

  create_folder(tmp_dir)

  book_json = get_json("/api1/rs/page/hoerbuecher/#{slug}")
  cover_path = download_cover(book_json, tmp_dir)

  progress_bar = ProgressBar.create(format: "%a %b\e[93m\u{15E7}\e[0m%i %p%% #{book_json['title']}",
                                    progress_mark: ' ',
                                    remainder_mark: "\u{FF65}",
                                    total: book_json['files'].count)

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

audiobooks.each do |base_json|
  download_audiobook(base_json)
end
