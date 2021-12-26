#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'net/http'
require 'open-uri'
require 'ruby-progressbar'
require_relative 'iceportal/base'

IcePortal::Magazines.all.each do |base_json|
  IcePortal::Magazines.download(base_json)
end

IcePortal::Audiobooks.all.each do |base_json|
  IcePortal::Audiobooks.download(base_json)
end
