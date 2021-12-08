RSpec.describe Relaton3gpp::DataFetcher do
  it "create output dir and run fetcher" do
    expect(Dir).to receive(:exist?).with("dir").and_return(false)
    expect(FileUtils).to receive(:mkdir_p).with("dir")
    fetcher = double("fetcher")
    expect(fetcher).to receive(:fetch)
    expect(Relaton3gpp::DataFetcher)
      .to receive(:new).with("dir", "xml").and_return(fetcher)
    Relaton3gpp::DataFetcher.fetch output: "dir", format: "xml"
  end

  context "instance" do
    subject { Relaton3gpp::DataFetcher.new("dir", "bibxml") }

    it "initialize fetcher" do
      expect(subject.instance_variable_get(:@ext)).to eq "xml"
      expect(subject.instance_variable_get(:@files)).to eq []
      expect(subject.instance_variable_get(:@output)).to eq "dir"
      expect(subject.instance_variable_get(:@format)).to eq "bibxml"
      expect(subject).to be_instance_of(Relaton3gpp::DataFetcher)
    end

    context "fetch data" do
      before do
        # resp = '{"items":[{"path":"path/file.xml"}],"total_count":1}'
        # expect(Net::HTTP).to receive(:get).and_return resp
      end

      it "get file" do
        ftp = double("ftp")
        expect(ftp).to receive(:resume=).with(true)
        expect(ftp).to receive(:login)
        expect(ftp).to receive(:chdir).with("/Information/Databases/Spec_Status/")
        expect(ftp).to receive(:list).with("*.zip").and_return(["11-22-21  02:39PM            459946195 file.zip"])
        expect(File).to receive(:exist?).with("file.zip").and_return(false)
        expect(ftp).to receive(:getbinaryfile).with("file.zip")
        expect(Net::FTP).to receive(:new).and_return ftp
        expect(subject.get_file).to eq "file.zip"
      end

      it "fetch" do
        expect(subject).to receive(:get_file).and_return("file.zip")
        zip = double("zip")
        input_stream = double("input_stream", read: "data")
        entry = double("entry", get_input_stream: input_stream)
        entries = double("entries", first: entry)
        expect(zip).to receive(:glob).with("status_smg_3GPP.mdb").and_return(entries)
        expect(Zip::File).to receive(:open).with("file.zip").and_yield(zip)
        expect(File).to receive(:write).with("status_smg_3GPP.mdb", "data")
        dbs = { "2001-04-25_schedule" => [spec: "00.00"] }
        expect(Mdb).to receive(:open).with("status_smg_3GPP.mdb").and_return(dbs)
        expect(subject).to receive(:fetch_doc).with({ spec: "00.00" }, dbs)
        subject.fetch
      end

      it "successfully" do
        row = { Number: "00.00" }
        dbs = double("dbs")
        doc = double("doc")
        expect(Relaton3gpp::Parser).to receive(:parse).with(row, dbs).and_return doc
        expect(subject).to receive(:save_doc).with(doc)
        subject.fetch_doc row, dbs
      end

      it "warn when error" do
        row = { Number: "00.00" }
        dbs = double("dbs")
        expect(Relaton3gpp::Parser).to receive(:parse).and_raise(StandardError)
        expect { subject.fetch_doc(row, dbs) }.to output(/Error: StandardError\. Number: 00\.00/).to_stderr
      end
    end

    context "save doc" do
      it "skip" do
        expect(subject).not_to receive(:file_name)
        subject.save_doc nil
      end

      it "bibxml" do
        bib = double("bib", docnumber: "bib")
        expect(bib).to receive(:to_bibxml).and_return("<xml/>")
        expect(File).to receive(:write)
          .with("dir/bib.xml", "<xml/>", encoding: "UTF-8")
        subject.save_doc bib
      end

      it "xml" do
        subject.instance_variable_set(:@format, "xml")
        bib = double("bib", docnumber: "bib")
        expect(bib).to receive(:to_xml).with(bibdata: true).and_return("<xml/>")
        expect(File).to receive(:write)
          .with("dir/bib.xml", "<xml/>", encoding: "UTF-8")
        subject.save_doc bib
      end

      it "yaml" do
        subject.instance_variable_set(:@format, "yaml")
        subject.instance_variable_set(:@ext, "yaml")
        bib = double("bib", docnumber: "bib")
        expect(bib).to receive(:to_hash).and_return({ id: 123 })
        expect(File).to receive(:write)
          .with("dir/bib.yaml", /id: 123/, encoding: "UTF-8")
        subject.save_doc bib
      end

      it "warn when file exists" do
        subject.instance_variable_set(:@files, ["dir/bib.xml"])
        bib = double("bib", docnumber: "bib")
        expect(bib).to receive(:to_bibxml).and_return("<xml/>")
        expect(File).to receive(:write)
          .with("dir/bib.xml", "<xml/>", encoding: "UTF-8")
        expect { subject.save_doc bib }
          .to output(/File dir\/bib.xml already exists/).to_stderr
      end
    end
  end

  # it do
  #   Relaton3gpp::DataFetcher.fetch
  # end
end
