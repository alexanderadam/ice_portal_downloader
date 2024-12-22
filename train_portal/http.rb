require 'open3'
require 'tty-progressbar'

module TrainPortal
  module API
    def get(path, full_response: false)
      left_tries ||= 3
      uri = URI(Addressable::URI.encode_component("#{base_url}#{path}"))
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = uri.scheme == 'https'
      request = Net::HTTP::Get.new(uri)
      cookies = get_cookies
      request['Cookie'] = cookies if cookies
      response = http.request(request)

      set_cookies(response.get_fields('set-cookie'))

      full_response ? response : response.body
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

    def file_download(url_path, file_path, skip_progress_bar: false)
      file_path = file_path.sub(%r{^/}, '')
      file_path = TrainPortal.download_directory(file_path)
      return file_path if File.exist?(file_path)

      FileUtils.mkdir_p File.dirname(file_path)

      uri = URI(Addressable::URI.encode_component("#{base_url}#{url_path}"))
      total_size = Net::HTTP.get_response(uri)['content-length'].to_i

      bar = TTY::ProgressBar.new("[:bar] :percent :eta", total: total_size) unless skip_progress_bar

      File.open(file_path, 'wb') do |file|
        Net::HTTP.get_response(uri) do |response|
          response.read_body do |chunk|
            file.write(chunk)
            bar.advance(chunk.size) unless skip_progress_bar
          end
        end
      end
      file_path
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

    def current_ssid
      stdout, _stderr, status = Open3.capture3('nmcli -t -f active,ssid dev wifi | egrep "^yes" | cut -d: -f2')

      stdout.strip if status.success?
    rescue
      nil
    end

    def title = "#{portal_name} Media Downloader in #{current_ssid}".strip
    def portal_name = ancestors.first.name.split('::')[1]
  end
end
