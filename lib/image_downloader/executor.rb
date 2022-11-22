# frozen_string_literal: true

module ImageDownloader
  class Executor
    def initialize(file_path)
      @file_path = file_path
    end

    def call
      abort unless FileValidator.new(file_path).valid?

      ImageDownloader.logger.info "Found #{urls.count} urls in the provided file"

      create_folder!
      fetch_images!

      ImageDownloader.logger.info 'Done!'
    end

    private

    attr_reader :file_path

    def create_folder!
      ImageDownloader.logger.info "Creating a new folder: '#{dirname}'"
      FileUtils.mkdir_p(dirname)
    end

    def fetch_images!
      Fetcher.new(dirname, urls).call
    end

    def dirname
      @dirname ||= "images-#{Time.now.strftime('%Y%m%d%H%M%S')}"
    end

    def urls
      @urls ||= File.read(file_path).split
    end
  end
end
