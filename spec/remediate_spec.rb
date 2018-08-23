require 'spec_helper'

describe PreAssembly::Remediation::Item do
  let(:pid) { 'druid:cs575bk5522' }
  let(:item) { described_class.new(pid) }

  describe '#pid' do
    it 'returns value from initialization' do
      expect(item.pid).to eql(pid)
    end
  end

  context 'logging' do
    let(:log_dir) { File.dirname(__FILE__) + "/test_data/logging" }
    let(:csv_filename) { log_dir + "/csv_log.csv" }
    let(:progress_log_file) { log_dir + "/progress_log_file.yml" }

    before { Dir.mkdir(log_dir) unless Dir.exist?(log_dir) }

    after { File.delete(csv_filename) if File.exist?(csv_filename) }

    it "ensures a log file exists" do
      File.delete(csv_filename) if File.exist?(csv_filename)
      expect { item.ensureLogFile(csv_filename) }.to change { File.exist?(csv_filename) }.from(false).to(true)
      expect(File.file?(csv_filename)).to be(true)
    end
    it "takes a CSV file for logging" do
      expect { item.log_to_csv(csv_filename) }.not_to raise_error
    end
    it "logs to a progress file as yml" do
      expect { item.log_to_progress_file(progress_log_file) }.not_to raise_error
    end
  end
end
