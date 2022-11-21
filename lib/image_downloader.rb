# frozen_string_literal: true

require 'fileutils'
require 'concurrent-ruby'
require 'httparty'

require 'image_downloader/file_validator'
require 'image_downloader/version'

class ImageDownloader
  attr_reader :logger, :file_path

  def initialize(file_path)
    @logger = Logger.new(STDOUT)
    @file_path = file_path
  end

  def call
    raise 'File not found' unless File.file? file_path
    raise 'File is to big' if File.size(file_path) > 1000000


    dirname = "images-#{Time.now.strftime('%Y%m%d%H%M%S')}"
    logger.info "Creating the new folder: #{dirname}"
    dirname.tap(&FileUtils.method(:mkdir_p))

    urls = File.readlines(file_path).map(&:strip)

    logger.info "Validating urls.."
    urls.each {|url| URI.parse(url) }
    logger.info "All urls are valid"

    pool = Concurrent::FixedThreadPool.new([urls.count, Concurrent.processor_count].min)

    urls.map.with_index(1) do |url, i|
      Concurrent::Promise.execute(executor: pool) do
        logger.info "#{i} - Downloading from #{url.length > 120 ? "#{url[0...120]}..." : url}"
        response = HTTParty.get(url)

        type, ext = response.content_type.split('/')

        raise 'bad type' if type != 'image'

        File.binwrite(File.join(dirname, "#{i}.#{ext}"), response.body)
      end
    end.each(&:value)
  ensure
    pool&.tap(&:shutdown)&.wait_for_termination
  end
end
