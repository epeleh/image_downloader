# frozen_string_literal: true

module ImageDownloader
  class Executor
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def call
      abort unless FileValidator.new(file_path).valid?

      ImageDownloader.logger.info "Found #{urls.count} urls in the provided file"

      create_images_folder!
      download_images!

      ImageDownloader.logger.info 'Done!'

      nil
    end

    private

    def create_images_folder!
      ImageDownloader.logger.info "Creating a new folder: '#{dirname}'"
      FileUtils.mkdir_p(dirname)
    end

    def download_images!
      threads_num = [urls.count, Concurrent.processor_count].min
      ImageDownloader.logger.info "Process downloadings in #{threads_num} threads:"
      pool = Concurrent::FixedThreadPool.new(threads_num)

      downloaded_count = urls.map.with_index(1) do |url, i|
        Concurrent::Promise.execute(executor: pool) do
          ImageDownloader.logger.info "[#{i}] Start downloading from: '#{ImageDownloader.truncate_url(url)}'"

          response = HTTParty.get(url, timeout: 10)
          raise "Bad status: #{response.code}" unless response.ok?

          type, ext = response.content_type.split('/')
          raise "Bad content type: '#{type}'" if type != 'image'

          name = File.join(dirname, "#{i}.#{ext}")
          File.binwrite(name, response.body)

          ImageDownloader.logger.info "[#{i}] Image saved as '#{name}'"
          true
        rescue StandardError => e
          ImageDownloader.logger.error "[#{i}] " + e.message
          false
        end
      end.map(&:value!).count(&:itself)

      ImageDownloader.logger.info(
        "#{downloaded_count} images downloaded, #{urls.count - downloaded_count} errors"
      )
    ensure
      pool&.tap(&:shutdown)&.wait_for_termination
    end

    def dirname
      @dirname ||= "images-#{Time.now.strftime('%Y%m%d%H%M%S')}"
    end

    def urls
      @urls ||= File.readlines(file_path).map(&:strip).reject(&:empty?)
    end
  end
end
