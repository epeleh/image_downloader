# frozen_string_literal: true

module ImageDownloader
  class FileValidator
    MAX_FILE_SIZE = 1_000_000 # 1 MB

    def initialize(file_path)
      @file_path = file_path
    end

    def call
      validate_file_path && validate_urls
    end

    alias valid? call

    private

    attr_reader :file_path

    def validate_file_path
      return true if file_path_error_message.nil?

      ImageDownloader.logger.error file_path_error_message
      false
    end

    def validate_urls
      urls.map do |url|
        next true if ImageDownloader.valid_url?(url)

        msg = "Provided file contains bad url: '#{ImageDownloader.truncate_url(url)}'"
        ImageDownloader.logger.error msg

        false
      end.all?
    end

    def file_path_error_message
      @file_path_error_message ||=
        if file_path.nil?
          'You should provide a file path as the first argument'
        elsif !File.file?(file_path)
          "Provided file not found: '#{file_path}'"
        elsif File.empty?(file_path)
          "Provided file is empty: '#{file_path}'"
        elsif File.size(file_path) > MAX_FILE_SIZE
          "Provided file is too big: '#{file_path}'"
        end
    end

    def urls
      @urls ||= File.read(file_path).split
    end
  end
end
