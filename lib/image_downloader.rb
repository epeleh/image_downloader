# frozen_string_literal: true

require 'fileutils'
require 'concurrent-ruby'
require 'httparty'

require 'image_downloader/executor'
require 'image_downloader/fetcher'
require 'image_downloader/file_validator'
require 'image_downloader/version'

module ImageDownloader
  def self.logger
    @logger ||= Logger.new($stdout)
  end

  def self.truncate_url(url)
    url.length > 120 ? "#{url[0...(120 - 3)]}..." : url
  end

  def self.valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) && !uri.host.nil?
  rescue URI::InvalidURIError
    false
  end
end
