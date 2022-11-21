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

  spec.required_ruby_version = Gem::Requirement.new('>= ' + File.read('.ruby-version').strip)

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.executables << 'image_downloader'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
