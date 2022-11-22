# frozen_string_literal: true

RSpec.describe ImageDownloader::FileValidator do
  let(:tempfile) { Tempfile.new }

  describe '#call' do
    subject { described_class.new(file_path).call }

    context 'when file_path argument is nil' do
      let!(:file_path) { nil }

      it 'returns false' do
        expect(subject).to be false
      end

      it 'writes correct logs' do
        expect(ImageDownloader.logger).to receive(:error).with(
          'You should provide a file path as the first argument'
        )

        subject
      end
    end

    context 'when the provided file is empty' do
      let!(:file_path) { tempfile.path }

      it 'returns false' do
        expect(subject).to be false
      end

      it 'writes correct logs' do
        expect(ImageDownloader.logger).to receive(:error).with(
          "Provided file is empty: '#{file_path}'"
        )

        subject
      end
    end

    context 'when the provided file not found' do
      let!(:file_path) { tempfile.path }

      before { tempfile.unlink }

      it 'returns false' do
        expect(subject).to be false
      end

      it 'writes correct logs' do
        expect(ImageDownloader.logger).to receive(:error).with(
          "Provided file not found: '#{file_path}'"
        )

        subject
      end
    end

    context 'when the provided file is too big' do
      let!(:file_path) { tempfile.path }

      before do
        tempfile.write('x' * described_class::MAX_FILE_SIZE.succ)
        tempfile.close
      end

      it 'returns false' do
        expect(subject).to be false
      end

      it 'writes correct logs' do
        expect(ImageDownloader.logger).to receive(:error).with(
          "Provided file is too big: '#{file_path}'"
        )

        subject
      end
    end

    context 'when the provided file contains bad urls' do
      let!(:file_path) { tempfile.path }

      before do
        tempfile.write <<~TEXT
          https://www.google.com:81 bad_url/123
          https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png
          oops://oops https://www.google.com##!
        TEXT
        tempfile.close
      end

      it 'returns false' do
        expect(subject).to be false
      end

      it 'writes correct logs' do
        expect(ImageDownloader.logger).to receive(:error).with(
          "Provided file contains bad url: 'bad_url/123'"
        ).ordered

        expect(ImageDownloader.logger).to receive(:error).with(
          "Provided file contains bad url: 'oops://oops'"
        ).ordered

        expect(ImageDownloader.logger).to receive(:error).with(
          "Provided file contains bad url: 'https://www.google.com##!'"
        ).ordered

        subject
      end
    end
  end

  describe '#valid?' do
    let(:file_validator) { described_class.new(nil) }

    it 'is alias for #call' do
      expect(file_validator.method(:valid?)).to eq file_validator.method(:call)
    end
  end
end
