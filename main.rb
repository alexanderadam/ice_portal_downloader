#!/usr/bin/env ruby

require 'fileutils'
require 'json'
require 'net/http'
require 'open-uri'
require 'tty-prompt'
require_relative 'train_portal/base'

train_portal = TrainPortal.train_portal
api = train_portal::API

prompt = TTY::Prompt.new
media_choices = api.media.map.with_index { |media, index| [media, index + 1] }.to_h

selection = prompt.select(api.title, media_choices.transform_keys {|mod| mod.name.split('::').last })
media = media_choices.to_h.invert[selection]

if media.nil?
  puts 'Invalid selection'
  exit 1
end

media_items = media.select_hash
selected_items = prompt.multi_select("Selected downloads:", media_items)

if selected_items.empty?
  puts 'No items selected'
  exit 1
end

selected_items.each do |index|
  base_json = media.all[index]
  media.download(base_json)
end
