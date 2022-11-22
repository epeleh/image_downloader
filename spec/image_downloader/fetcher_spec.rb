# frozen_string_literal: true

RSpec.describe ImageDownloader::Fetcher do
  let(:dirname) { Dir.mktmpdir }

  describe '#call' do
    subject { described_class.new(dirname, urls).call }

    context 'when the provided file contains valid urls', vcr: { cassette_name: 'valid_urls' } do
      let(:urls) do
        [
          'https://via.placeholder.com/300/09f/fff.png',
          'http://i.kym-cdn.com/entries/icons/original/000/016/546/hidethepainharold.jpg'
        ]
      end

      it 'downloads images' do
        expect { subject }.to change {
          Dir.glob File.join(dirname, '*')
        }.from([]).to(["#{dirname}/1.png", "#{dirname}/2.jpeg"])
      end

      it 'writes correct logs' do
        expected_log = <<-LOG
          INFO -- : Processing downloads in 1 threads:
          INFO -- : [1] Start downloading from: 'https://via.placeholder.com/300/09f/fff.png'
          INFO -- : [1] Image saved as '#{dirname}/1.png'
          INFO -- : [2] Start downloading from: 'http://i.kym-cdn.com/entries/icons/original/000/016/546/hidethepainharold.jpg'
          INFO -- : [2] Image saved as '#{dirname}/2.jpeg'
          INFO -- : 2 images downloaded, 0 errors
        LOG

        expected_log.each_line do |line|
          type, msg = line.strip.split(' -- : ')
          expect(ImageDownloader.logger).to receive(type.downcase).with(msg).ordered
        end

        subject
      end
    end

    context 'when the provided file contains bad urls', vcr: { cassette_name: 'bad_urls' } do
      let(:urls) do
        [
          'https://www.nyan.cat',
          'https://google.com/not-found.jpg',
          'https://www.google.com:81',
          'https://jsonplaceholder.typicode.com/todos/1',
          'https://redirect.once.org',
          'https://infinite.redirect.1.org',
          'https://infinite.redirect.2.org'
        ]
      end

      before do
        stub_request(:get, 'https://www.google.com:81').to_timeout
        stub_request(:get, 'https://redirect.once.org').to_return(
          status: 301, headers: { 'Location' => 'https://jsonplaceholder.typicode.com/todos/1' }
        )
        stub_request(:get, 'https://infinite.redirect.1.org').to_return(
          status: 301, headers: { 'Location' => 'https://infinite.redirect.2.org' }
        )
        stub_request(:get, 'https://infinite.redirect.2.org').to_return(
          status: 301, headers: { 'Location' => 'https://infinite.redirect.1.org' }
        )
      end

      it "doesn't download images" do
        expect { subject }.not_to(change { Dir.glob File.join(dirname, '*') })
      end

      it 'writes correct logs' do
        expected_log = <<-LOG
           INFO -- : Processing downloads in 1 threads:
           INFO -- : [1] Start downloading from: 'https://www.nyan.cat'
          ERROR -- : [1] Bad content type: 'text'
           INFO -- : [2] Start downloading from: 'https://google.com/not-found.jpg'
          ERROR -- : [2] Bad status: 404
           INFO -- : [3] Start downloading from: 'https://www.google.com:81'
          ERROR -- : [3] execution expired
           INFO -- : [4] Start downloading from: 'https://jsonplaceholder.typicode.com/todos/1'
          ERROR -- : [4] Bad content type: 'application'
           INFO -- : [5] Start downloading from: 'https://redirect.once.org'
          ERROR -- : [5] Bad content type: 'application'
           INFO -- : [6] Start downloading from: 'https://infinite.redirect.1.org'
          ERROR -- : [6] HTTP redirects too deep
           INFO -- : [7] Start downloading from: 'https://infinite.redirect.2.org'
          ERROR -- : [7] HTTP redirects too deep
           INFO -- : 0 images downloaded, 7 errors
        LOG

        expected_log.each_line do |line|
          type, msg = line.strip.split(' -- : ')
          expect(ImageDownloader.logger).to receive(type.downcase).with(msg).ordered
        end

        subject
      end
    end
  end
end
