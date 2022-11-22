# frozen_string_literal: true

require 'bundler/setup'
require 'image_downloader'

require 'tempfile'
require 'vcr'
require 'webmock/rspec'

ImageDownloader.logger.level = Logger::FATAL

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do |example|
    next if config.files_to_run.one?

    path = example.metadata.dig(:example_group, :file_path)
    current_path = config.instance_variable_get(:@current_file_path)

    if current_path.nil? || path != current_path
      config.instance_variable_set(:@current_file_path, path)
      puts unless current_path.nil?
      print "#{path} "
    end
  end
end
