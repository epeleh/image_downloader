# frozen_string_literal: true

module ImageDownloader
  class Executor
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def call
      abort unless FileValidator.new(file_path).valid?
      download_images!
      nil
    end

    private

    def download_images!
      pool = Concurrent::FixedThreadPool.new([urls.count, Concurrent.processor_count].min)

      urls.map.with_index(1) do |url, i|
        Concurrent::Promise.execute(executor: pool) do
          ImageDownloader.logger.info "[#{i}] Downloading from: '#{ImageDownloader.truncate_url(url)}'"
          response = HTTParty.get(url)

          type, ext = response.content_type.split('/')
          raise "Bad content type: '#{type}'" if type != 'image'

          name = File.join(dirname, "#{i}.#{ext}")
          File.binwrite(name, response.body)

          ImageDownloader.logger.info "[#{i}] Image saved as '#{name}'"
        rescue StandardError => e
          ImageDownloader.logger.error "[#{i}] " + e.message
        end
      end.each(&:wait!)
    ensure
      pool&.tap(&:shutdown)&.wait_for_termination
    end

    def dirname
      @dirname ||= begin
        name = "images-#{Time.now.strftime('%Y%m%d%H%M%S')}"

        ImageDownloader.logger.info "Creating the new folder: #{name}"
        FileUtils.mkdir_p(name)

        name
      end
    end

    def urls
      @urls ||= File.readlines(file_path).map(&:strip).reject(&:empty?)
    end
  end
end
