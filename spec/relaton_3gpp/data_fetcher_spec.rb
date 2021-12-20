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
      context "get file" do
        let(:ftp) do
          f = double("ftp")
          expect(f).to receive(:resume=).with(true).at_least(:once)
          expect(f).to receive(:login).at_least(:once)
          expect(f).to receive(:chdir).with("/Information/Databases/Spec_Status/").at_least(:once)
          expect(f).to receive(:list).with("*.zip").and_return(
            ["11-22-21  02:39PM            459946195 file.zip"],
          ).at_least(:once)
          f
        end

        before do
          expect(Net::FTP).to receive(:new).and_return(ftp).at_least(:once)
        end

        it "skip if no updates" do
          expect(File).to receive(:exist?).with(Relaton3gpp::DataFetcher::CURRENT).and_return(true)
          expect(YAML).to receive(:load_file).with(Relaton3gpp::DataFetcher::CURRENT).and_return(
            { "file" => "file.zip", "date" => "2021-11-22T14:39:00+00:00" },
          )
          expect(subject.get_file).to be_nil
        end

        it "download fist time" do
          expect(File).to receive(:exist?).with(Relaton3gpp::DataFetcher::CURRENT).and_return(false)
          expect(ftp).to receive(:getbinaryfile).with("file.zip")
          expect(subject.get_file).to eq "file.zip"
        end

        it "download update" do
          expect(File).to receive(:exist?).with(Relaton3gpp::DataFetcher::CURRENT).and_return(true)
          expect(YAML).to receive(:load_file).with(Relaton3gpp::DataFetcher::CURRENT).and_return(
            { "file" => "file.zip", "date" => "2021-11-23T14:39:00+00:00" },
          )
          expect(ftp).to receive(:getbinaryfile).with("file.zip")
          expect(subject.get_file).to eq "file.zip"
        end

        it "retry file downloading from FTP" do
          expect(ftp).to receive(:getbinaryfile).with("file.zip").and_raise(Net::ReadTimeout).exactly(5).times
          expect do
            subject.get_file
          end.to raise_error(Net::ReadTimeout)
        end
      end

      it "fetch" do
        expect(subject).to receive(:get_file).and_return("file.zip")
        zip = double("zip")
        input_stream = double("input_stream", read: "data")
        entry = double("entry", get_input_stream: input_stream)
        entries = double("entries", first: entry)
        expect(zip).to receive(:glob).with("status_smg_3GPP.mdb").and_return(entries)
        expect(Zip::File).to receive(:open).with("file.zip").and_yield(zip)
        file = double("file")
        expect(file).to receive(:write).with("data")
        expect(File).to receive(:open).with("status_smg_3GPP.mdb", "wb").and_yield(file)
        dbs = {
          "2001-04-25_schedule" => [spec: "00.00"],
          "Specs_GSM+3G" => :specs,
          "Specs_GSM+3G_release-info" => :specrels,
          "Releases" => :releases,
        }
        expect(Mdb).to receive(:open).with("status_smg_3GPP.mdb").and_return(dbs)
        expect(subject).to receive(:fetch_doc).with({ spec: "00.00" }, :specs, :specrels, :releases)
        expect(File).to receive(:write).with(Relaton3gpp::DataFetcher::CURRENT, kind_of(String), encoding: "UTF-8")
        subject.fetch
      end

      it "successfully" do
        row = { spec: "00.00" }
        # dbs = double("dbs")
        # doc = double("doc")
        expect(Relaton3gpp::Parser).to receive(:parse).with(row, :specs, :specrels, :releases).and_return :doc
        expect(subject).to receive(:save_doc).with(:doc)
        subject.fetch_doc row, :specs, :specrels, :releases
      end

      it "warn when error" do
        row = { spec: "00.00", release: "R00", MAJOR_VERSION_NB: "1",
                TECHNICAL_VERSION_NB: "2", EDITORIAL_VERSION_NB: "3" }
        expect(Relaton3gpp::Parser).to receive(:parse).and_raise(StandardError)
        expect { subject.fetch_doc(row, :specs, :specrels, :releases) }
          .to output(/Error: StandardError\nPubID: 00\.00:R00\/1\.2\.3/m).to_stderr
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
          .with("dir/BIB.xml", "<xml/>", encoding: "UTF-8")
        subject.save_doc bib
      end

      it "xml" do
        subject.instance_variable_set(:@format, "xml")
        bib = double("bib", docnumber: "bib")
        expect(bib).to receive(:to_xml).with(bibdata: true).and_return("<xml/>")
        expect(File).to receive(:write)
          .with("dir/BIB.xml", "<xml/>", encoding: "UTF-8")
        subject.save_doc bib
      end

      it "yaml" do
        subject.instance_variable_set(:@format, "yaml")
        subject.instance_variable_set(:@ext, "yaml")
        bib = double("bib", docnumber: "bib")
        expect(bib).to receive(:to_hash).and_return({ id: 123 })
        expect(File).to receive(:write)
          .with("dir/BIB.yaml", /id: 123/, encoding: "UTF-8")
        subject.save_doc bib
      end

      it "warn when file exists" do
        subject.instance_variable_set(:@files, ["dir/BIB.xml"])
        bib = double("bib", docnumber: "bib")
        expect(bib).to receive(:to_bibxml).and_return("<xml/>")
        expect(File).to receive(:write)
          .with("dir/BIB.xml", "<xml/>", encoding: "UTF-8")
        expect { subject.save_doc bib }
          .to output(/File dir\/BIB.xml already exists/).to_stderr
      end
    end
  end

  # it do
  #   Relaton3gpp::DataFetcher.fetch
  # end
end
