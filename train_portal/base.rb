require_relative 'api'
require_relative 'support'

module TrainPortal
  module_function
  SUPPORTED_PORTALS = %w[Ice Oebb CeskeDrahy]

  SUPPORTED_PORTALS.each { |portal| require_relative "#{portal.downcase}/base" }

  def train_portal
    @train_portal ||= begin
      classes = SUPPORTED_PORTALS.map { |portal| Object.const_get("TrainPortal::#{portal}") }
      portal = classes.find { |c| c::API.active? } || begin
        puts 'No known media portal found'
        exit 1
      end
    end
  end

  def download_directory(sub_path = nil)
    @download_directory ||= File.expand_path('./downloads')
    return @download_directory if sub_path.nil?

    File.join(@download_directory, sub_path)
  end
end
