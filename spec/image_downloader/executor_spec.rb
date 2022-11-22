# frozen_string_literal: true

RSpec.describe ImageDownloader::Executor do
  let(:tempfile) { Tempfile.new }
  let(:file_path) { tempfile.path }

  before do
    tempfile.write <<~TEXT
        https://www.google.com:81  https://via.placeholder.com/300/09f/fff.png
      https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png
    TEXT
    tempfile.close
  end

  describe '#call' do
    subject { described_class.new(file_path).call }

    let(:dirname) { Dir.mktmpdir.tap(&FileUtils.method(:rm_r)) }

    before do
      allow_any_instance_of(described_class).to receive(:dirname).and_return(dirname)
      allow_any_instance_of(ImageDownloader::FileValidator).to receive(:valid?).and_return(true)
      allow_any_instance_of(ImageDownloader::Fetcher).to receive(:call)
    end

    it 'creates a new folder' do
      expect { subject }.to change { File.directory? dirname }.from(false).to(true)
    end

    it 'fetches images' do
      fetcher = instance_double(ImageDownloader::Fetcher)

      allow(ImageDownloader::Fetcher).to receive(:new).with(
        dirname, [
          'https://www.google.com:81', 'https://via.placeholder.com/300/09f/fff.png',
          'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png'
        ]
      ).and_return(fetcher)

      expect(fetcher).to receive(:call).with(no_args)

      subject
    end

    it 'writes correct logs' do
      expect(ImageDownloader.logger).to receive(:info).with(
        'Found 3 urls in the provided file'
      ).ordered

      expect(ImageDownloader.logger).to receive(:info).with(
        "Creating a new folder: '#{dirname}'"
      ).ordered

      expect(ImageDownloader.logger).to receive(:info).with('Done!').ordered

      subject
    end
  end
end
