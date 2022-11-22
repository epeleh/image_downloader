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

  describe '#call', vcr: { cassette_name: 'some_urls' } do
    subject { described_class.new(file_path).call }

    let(:dirname) { Dir.mktmpdir.tap(&FileUtils.method(:rm_r)) }

    before do
      stub_request(:get, 'https://www.google.com:81').to_timeout
      allow_any_instance_of(described_class).to receive(:dirname).and_return(dirname)
    end

    it 'creates a new folder' do
      expect { subject }.to change { File.directory? dirname }.from(false).to(true)
    end

    it 'fetches images' do
      expect(ImageDownloader::Fetcher).to receive(:new).with(
        dirname, [
          'https://www.google.com:81', 'https://via.placeholder.com/300/09f/fff.png',
          'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png'
        ]
      ).and_call_original

      expect { subject }.to change {
        Dir.glob File.join(dirname, '*')
      }.from([]).to(["#{dirname}/2.png", "#{dirname}/3.png"])
    end

    it 'writes correct logs' do
      expected_log = <<-LOG
         INFO -- : Found 3 urls in the provided file
         INFO -- : Creating a new folder: '#{dirname}'
         INFO -- : Processing downloads in 1 threads:
         INFO -- : [1] Start downloading from: 'https://www.google.com:81'
        ERROR -- : [1] execution expired
         INFO -- : [2] Start downloading from: 'https://via.placeholder.com/300/09f/fff.png'
         INFO -- : [2] Image saved as '#{dirname}/2.png'
         INFO -- : [3] Start downloading from: 'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png'
         INFO -- : [3] Image saved as '#{dirname}/3.png'
         INFO -- : 2 images downloaded, 1 errors
         INFO -- : Done!
      LOG

      expected_log.each_line do |line|
        type, msg = line.strip.split(' -- : ')
        expect(ImageDownloader.logger).to receive(type.downcase).with(msg).ordered
      end

      subject
    end
  end
end
