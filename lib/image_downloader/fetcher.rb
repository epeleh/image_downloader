# frozen_string_literal: true

module ImageDownloader
  class Fetcher
    def initialize(dirname, urls, threads_num = [urls.count, Concurrent.processor_count].min)
      @dirname = dirname
      @urls = urls
      @threads_num = threads_num
    end

    def call
      ImageDownloader.logger.info "Processing downloads in #{threads_num} threads:"
      downloaded_count = download_images!

      msg = "#{downloaded_count} images downloaded, #{urls.count - downloaded_count} errors"
      ImageDownloader.logger.info msg
    end

    private

    attr_reader :dirname, :urls, :threads_num

    def download_images!
      pool = Concurrent::FixedThreadPool.new(threads_num)

      promises = urls.map.with_index(1) do |url, i|
        Concurrent::Promise.execute(executor: pool) { process_url(url, i) }
      end

      promises.map(&:value!).count(&:itself)
    ensure
      pool.tap(&:shutdown).wait_for_termination
    end

    def process_url(url, thread_n)
      msg = "[#{thread_n}] Start downloading from: '#{ImageDownloader.truncate_url(url)}'"
      ImageDownloader.logger.info msg

      image_data, file_ext = fetch_image(url)

      file_name = File.join(dirname, "#{thread_n}.#{file_ext}")
      File.binwrite(file_name, image_data)

      ImageDownloader.logger.info "[#{thread_n}] Image saved as '#{file_name}'"
      true
    rescue StandardError => e
      ImageDownloader.logger.error "[#{thread_n}] #{e.message}"
      false
    end

    def fetch_image(url)
      response = HTTParty.get(url, timeout: 10)

      raise "Bad status: #{response.code}" unless response.ok?

      type, ext = response.content_type.split('/')
      raise "Bad content type: '#{type}'" if type != 'image'

      [response.body, ext]
    end
  end
end
