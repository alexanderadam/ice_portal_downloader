# frozen_string_literal: true

require 'addressable/uri'

module IcePortal
  module API
    module_function

    def get(path)
      left_tries ||= 3
      uri = URI(Addressable::URI.encode_component("https://iceportal.de#{path}"))
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = uri.scheme == 'https'
      request = Net::HTTP::Get.new(uri)
      cookies = get_cookies
      request['Cookie'] = cookies if cookies
      response = http.request(request)

      set_cookies(response.get_fields('set-cookie'))

      response.body
    rescue SocketError
      left_tries -= 1
      raise if left_tries <= 0

      retry
    end

    def get_json(path)
      body = get(path)
      JSON.parse(body)
    rescue => e
      binding.irb
    end

    def file_download(url_path, file_path)
      return puts("File #{File.basename(file_path)} already exists") if File.exist?(file_path)

      FileUtils.mkdir_p File.dirname(file_path)
      puts "Downloading #{File.basename(file_path)}"
      content = get(url_path)
      File.write file_path, content, mode: 'wb'
    end

    def set_cookies(all_cookies)
      return unless all_cookies
      cookies = all_cookies.reject { |c| ['', nil].include?(c) }.map { |c| c.split('; ').first }.join('; ')

      return if cookies.chomp == ''

      @@cookies = cookies
    end

    def get_cookies
      @@cookies ||= nil
      return if ['', nil].include?(@@cookies)

      @@cookies
    end
  end
end
