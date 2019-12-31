#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'mechanize'
require 'progress_bar'

DOWNLOAD_PATH = './audiobooks'.freeze

def create_folder(directory)
  FileUtils.mkdir_p(directory) unless File.directory?(directory)
end # create_folder

def client
  @browser ||= Mechanize.new
end

def audiobooks
  response = client.get('https://iceportal.de/api1/rs/page/hoerbuecher')

  # extract titles
  json_data = JSON.parse(response.body)

  json_data['teaserGroup']['items'].map do |item|
    item['navigation']['href']
  end
end # get_all_audiobooks

def download_audiobook(path)
  title = path.split('/').last
  puts("\nDownloading audiobook: #{title}")

  chapter_response = client.get("https://iceportal.de/api1/rs/page/hoerbuecher/#{title}")

  # extract chapters
  json_data = JSON.parse(chapter_response.body)
  playlist = json_data['files']

  # extract download_paths for each chapter
  download_paths = playlist.map do |chapter|
    url = "https://iceportal.de/api1/rs/audiobooks/path#{chapter['path']}"
    response_download_path = client.get(url)

    JSON.parse(response_download_path.body)['path']
  end

  create_folder("./#{DOWNLOAD_PATH}/#{title}")
  progress_bar = ProgressBar.new(download_paths.count)

  # download each track
  download_paths.each_with_index do |track, counter|
    progress_bar.increment!

    url = "https://iceportal.de#{track}"

    save_path = File.join(DOWNLOAD_PATH, title, "#{title}_#{counter + 1}.mp3")
    client.download(url, save_path)
  end
end # download_audiobook

# MAIN

# download all audibooks
audiobooks.each do |book|
  download_audiobook(book)
end
