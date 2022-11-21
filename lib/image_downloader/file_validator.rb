# frozen_string_literal: true

module ImageDownloader
  class FileValidator
    MAX_FILE_SIZE = 1_000_000 # 1 MB

    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
    end

    def call
      validate_file_path && validate_urls
    end

    alias valid? call

    private

    def validate_file_path
      if file_path.nil?
        ImageDownloader.logger.error 'You should provide a file path as the first argument'
        return false
      end

      unless File.file?(file_path)
        ImageDownloader.logger.error "Provided file not found: '#{file_path}'"
        return false
      end

      if File.empty?(file_path)
        ImageDownloader.logger.error "Provided file is empty: '#{file_path}'"
        return false
      end

      if File.size(file_path) > MAX_FILE_SIZE
        ImageDownloader.logger.error "Provided file is too big: '#{file_path}'"
        return false
      end

      true
    end

    def validate_urls
      urls.map.with_index(1) do |url, i|
        valid = begin
          uri = URI.parse(url)
          uri.is_a?(URI::HTTP) && !uri.host.nil?
        rescue URI::InvalidURIError
          false
        end

        unless valid
          ImageDownloader.logger.error(
            "Provided file contains bad url (line: #{i}): '#{ImageDownloader.truncate_url(url)}'"
          )
        end

        valid
      end.all?
    end

    def urls
      @urls ||= File.readlines(file_path).map(&:strip).reject(&:empty?)
    end
  end
end
