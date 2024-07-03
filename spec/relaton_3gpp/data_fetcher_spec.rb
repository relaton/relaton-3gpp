RSpec.describe Relaton3gpp::DataFetcher do
  it "create output dir and run fetcher" do
    expect(FileUtils).to receive(:mkdir_p).with("dir")
    fetcher = double("fetcher")
    expect(fetcher).to receive(:fetch)
    expect(Relaton3gpp::DataFetcher)
      .to receive(:new).with("dir", "xml").and_return(fetcher)
    Relaton3gpp::DataFetcher.fetch "status-smg-3GPP", output: "dir", format: "xml"
  end

  context "instance" do
    require "net/ftp"

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
          expect(f).to receive(:chdir).with("/Information/Databases/").at_least(:once)
          f
        end

        before do
          expect(Net::FTP).to receive(:new).and_return(ftp).at_least(:once)
        end

        context do
          before do
            expect(ftp).to receive(:list).with("*.csv").and_return(
              ["11-22-21  02:39PM            459946195 file.csv"],
            ).at_least(:once)
          end

          it "skip if no updates" do
            expect(File).to receive(:exist?).with(Relaton3gpp::DataFetcher::CURRENT).and_return(true)
            allow(File).to receive(:exist?).and_call_original
            expect(YAML).to receive(:load_file).with(Relaton3gpp::DataFetcher::CURRENT).and_return(
              { "file" => "file.csv", "date" => "2021-11-22T14:39:00+00:00" },
            )
            expect(subject.get_file(false)).to be_nil
          end

          it "download fist time" do
            expect(File).to receive(:exist?).with(Relaton3gpp::DataFetcher::CURRENT).and_return(false)
            expect(ftp).to receive(:get).with("file.csv", /3gpp\.csv$/)
            expect(subject.get_file(false)).to match(/3gpp.csv$/)
          end

          it "download update" do
            expect(File).to receive(:exist?).with(Relaton3gpp::DataFetcher::CURRENT).and_return(true)
            expect(YAML).to receive(:load_file).with(Relaton3gpp::DataFetcher::CURRENT).and_return(
              { "file" => "file.csv", "date" => "2021-11-23T14:39:00+00:00" },
            )
            expect(ftp).to receive(:get).with("file.csv", /3gpp\.csv$/)
            expect(subject.get_file(false)).to match(/3gpp.csv$/)
          end

          it "retry file downloading from FTP" do
            expect(ftp).to receive(:get).with("file.csv", /3gpp\.csv$/)
              .and_raise(Net::ReadTimeout).exactly(5).times
            expect do
              subject.get_file false
            end.to raise_error(Net::ReadTimeout)
          end

          it "download if current date is empty" do
            expect(File).to receive(:exist?).with(Relaton3gpp::DataFetcher::CURRENT).and_return(true)
            current = { "file" => "file.csv", "date" => "" }
            expect(YAML).to receive(:load_file).with(Relaton3gpp::DataFetcher::CURRENT).and_return current
            expect(ftp).to receive(:get).with("file.csv", /3gpp\.csv$/)
            expect(subject.get_file(false)).to match(/3gpp.csv$/)
          end
        end

        it "return nil if no files" do
          expect(ftp).to receive(:list).with("*.csv").and_return([])
          expect(subject.get_file(false)).to be_nil
        end
      end

      context "fetch" do
        it "skip if no file name" do
          expect(subject).to receive(:get_file).and_return nil
          expect(File).not_to receive(:exist?)
          subject.fetch true
        end

        context do
          before { expect(subject).to receive(:get_file).and_return "file.csv" }

          it "skip if file doesn't exist" do
            expect(File).to receive(:exist?).with("file.csv").and_return false
            expect(File).not_to receive(:size).with("file.csv")
            subject.fetch true
          end

          context do
            before do
             expect(File).to receive(:exist?).with("file.csv").and_return true
            end

            it "skip if file size is too small" do
              expect(File).to receive(:size).with("file.csv").and_return 1_000_000
              expect(CSV).not_to receive(:open)
              subject.fetch true
            end

            context "successfully" do
              before do
                expect(File).to receive(:size).with("file.csv").and_return 25_000_000
                expect(CSV).to receive(:open)
                  .with("file.csv", "r:bom|utf-8", headers: true, col_sep: ";").and_return [:row]
                expect(Relaton3gpp::Parser).to receive(:parse).with(:row).and_return :doc
                expect(subject).to receive(:save_doc).with(:doc)
                expect(File).to receive(:write).with("current.yaml", anything, encoding: "UTF-8")
                expect(subject.index).to receive(:save)
              end

              it "renewal" do
                expect(FileUtils).to receive(:rm_f).with("dir/*")
                expect(subject.index).to receive(:remove_all)
                subject.fetch true
              end

              it "update" do
                expect(FileUtils).not_to receive(:rm_f).with("dir/*")
                expect(subject.index).not_to receive(:remove_all)
                subject.fetch false
              end
            end
          end
        end
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
        expect(subject.index).to receive(:add_or_update).with("bib", "dir/BIB.xml")
        subject.save_doc bib
      end

      it "xml" do
        subject.instance_variable_set(:@format, "xml")
        bib = double("bib", docnumber: "bib")
        expect(bib).to receive(:to_xml).with(bibdata: true).and_return("<xml/>")
        expect(File).to receive(:write)
          .with("dir/BIB.xml", "<xml/>", encoding: "UTF-8")
        expect(subject.index).to receive(:add_or_update).with("bib", "dir/BIB.xml")
        subject.save_doc bib
      end

      it "yaml" do
        subject.instance_variable_set(:@format, "yaml")
        subject.instance_variable_set(:@ext, "yaml")
        bib = double("bib", docnumber: "bib")
        expect(bib).to receive(:to_hash).and_return({ id: 123 })
        expect(File).to receive(:write)
          .with("dir/BIB.yaml", /id: 123/, encoding: "UTF-8")
        expect(subject.index).to receive(:add_or_update).with("bib", "dir/BIB.yaml")
        subject.save_doc bib
      end

      it "warn when file exists" do
        subject.instance_variable_set(:@files, ["dir/BIB.xml"])
        bib = double("bib", docnumber: "bib")
        expect(bib).to receive(:to_bibxml).and_return("<xml/>")
        expect(File).to receive(:write)
          .with("dir/BIB.xml", "<xml/>", encoding: "UTF-8")
        expect(subject.index).to receive(:add_or_update).with("bib", "dir/BIB.xml")
        expect { subject.save_doc bib }
          .to output(/File dir\/BIB.xml already exists/).to_stderr_from_any_process
      end
    end
  end

  # it do
  #   Relaton3gpp::DataFetcher.fetch
  # end
end
