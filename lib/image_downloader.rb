# frozen_string_literal: true

require 'image_downloader/version'

class ImageDownloader
  def initialize(file_path)
    @file_path = file_path
  end

  def call
    raise NotImplementedError
  end
end
