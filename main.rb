#!/usr/bin/env ruby

require 'fileutils'
require 'json'
require 'net/http'
require 'open-uri'
require 'tty-prompt'
require 'pastel'
require_relative 'train_portal/base'

pastel = Pastel.new
train_portal = TrainPortal.train_portal
api = train_portal::API

def planned_exit
  puts Pastel.new.yellow("\n\n🚄 Bye")
  exit 0
end

Signal.trap("INT") { planned_exit }

prompt = TTY::Prompt.new
media_choices = api.media.map.with_index { |media, index| [media, index + 1] }.to_h

if media_choices.empty?
  puts pastel.red('❌ No media available')
  exit 1
end

cli_choices = media_choices.transform_keys { |mod| mod.respond_to?(:title) ? mod.title : mod.name.split('::').last }
begin
  selection = prompt.select(api.title, cli_choices)
rescue TTY::Reader::InputInterrupt
  planned_exit
end
media = media_choices.to_h.invert[selection]

if media.nil?
  puts pastel.red('❌ Invalid selection')
  exit 1
end

media_items = media.select_hash
begin
  selected_items = prompt.multi_select(pastel.yellow("📥 Select downloads:"), media_items, per_page: 8)
rescue TTY::Reader::InputInterrupt
  planned_exit
end

if selected_items.empty?
  puts pastel.red('❌ No items selected')
  exit 1
end

selected_items.each do |index|
  base_json = media.all[index]
  puts pastel.green("⬇️ Downloading: #{base_json['titleFull']}")
  media.download(base_json)
  puts pastel.green("✅ Download complete: #{base_json['titleFull']}")
end
