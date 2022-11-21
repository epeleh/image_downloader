# frozen_string_literal: true

module ImageDownloader
  class Fetcher
    attr_reader :dirname, :urls, :threads_num

    def initialize(dirname, urls, threads_num = [urls.count, Concurrent.processor_count].min)
      @dirname = dirname
      @urls = urls
      @threads_num = threads_num
    end

    def call
      ImageDownloader.logger.info "Process downloadings in #{threads_num} threads:"
      downloaded_count = download_images!

      ImageDownloader.logger.info(
        "#{downloaded_count} images downloaded, #{urls.count - downloaded_count} errors"
      )
    end

    private

    def download_images!
      pool = Concurrent::FixedThreadPool.new(threads_num)

      urls.map.with_index(1) do |url, i|
        Concurrent::Promise.execute(executor: pool) { process_url(url, i) }
      end.map(&:value!).count(&:itself)
    ensure
      pool.tap(&:shutdown).wait_for_termination
    end

    def process_url(url, num)
      ImageDownloader.logger.info "[#{num}] Start downloading from: '#{ImageDownloader.truncate_url(url)}'"
      response = HTTParty.get(url, timeout: 10)

      raise "Bad status: #{response.code}" unless response.ok?

      type, ext = response.content_type.split('/')
      raise "Bad content type: '#{type}'" if type != 'image'

      name = File.join(dirname, "#{num}.#{ext}")
      File.binwrite(name, response.body)

      ImageDownloader.logger.info "[#{num}] Image saved as '#{name}'"
      true
    rescue StandardError => e
      ImageDownloader.logger.error "[#{num}] " + e.message
      false
    end
  end
end
