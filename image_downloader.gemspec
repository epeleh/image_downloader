# frozen_string_literal: true

require_relative 'lib/image_downloader/version'

Gem::Specification.new do |spec|
  spec.name          = 'image_downloader'
  spec.version       = ImageDownloader::VERSION
  spec.authors       = ['Evgeny Peleh']
  spec.email         = ['pelehev@gmail.com']

  spec.homepage      = 'https://github.com/epeleh/image_downloader'
  spec.summary       = 'CLI application'
  spec.description   = 'Downloads images using a text file'
  spec.license       = 'MIT'

  spec.required_ruby_version = Gem::Requirement.new(">= #{File.read('.ruby-version').strip}")

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.executables << 'image_downloader'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.1'
  spec.add_runtime_dependency 'httparty', '~> 0.20.0'

  spec.add_development_dependency 'pry', '~> 0.13.1'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.15'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'webmock', '~> 3.18'
end
