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
                  .with("file.csv", "r:bom|utf-8", headers: true).and_return [:row]
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

      it "write doc" do
        bib = double("bib", docnumber: "bib")
        expect(bib).to receive(:to_bibxml).and_return("<xml/>")
        expect(File).to receive(:write).with("dir/BIB.xml", "<xml/>", encoding: "UTF-8")
        expect(subject.index).to receive(:add_or_update).with("bib", "dir/BIB.xml")
        subject.save_doc bib
      end

      it "warn when file exists and the doc is not transposed or has addidional cntributor" do
        subject.instance_variable_set(:@files, ["dir/BIB.xml"])
        bib = double("bib", docnumber: "bib")
        expect(subject).to receive(:merge_duplication).with(bib, "dir/BIB.xml").and_return nil
        expect(File).not_to receive(:write)
        expect(subject.index).not_to receive(:add_or_update)
        expect { subject.save_doc bib }
          .to output(/File dir\/BIB.xml already exists/).to_stderr_from_any_process
      end
    end

    context "serialise" do
      it "xml" do
        bib = double("bib")
        subject.instance_variable_set(:@format, "xml")
        expect(bib).to receive(:to_xml).with(bibdata: true).and_return("<xml/>")
        expect(subject.send(:serialise, bib)).to eq "<xml/>"
      end

      it "yaml" do
        bib = double("bib")
        subject.instance_variable_set(:@format, "yaml")
        expect(bib).to receive(:to_hash).and_return({ id: 123 })
        expect(subject.send(:serialise, bib)).to match(/id: 123/)
      end

      it "other" do
        bib = double("bib")
        expect(bib).to receive(:to_bibxml).and_return("<bibxm/>")
        expect(subject.send(:serialise, bib)).to eq "<bibxm/>"
      end
    end

    context "merge duplication" do
      before do
        expect(YAML).to receive(:load_file).with(:file).and_return :hash
        expect(Relaton3gpp::BibliographicItem).to receive(:from_hash).with(:hash).and_return :bib2
      end

      it "has changed link" do
        expect(subject).to receive(:update_link).with(:bib, :bib2).and_return true
        expect(subject).to receive(:transposed_relation).with(:bib, :bib2).and_return [:bib1, :bib2, false]
        expect(subject).to receive(:add_contributor).with(:bib1, :bib2).and_return false
        expect(subject.send(:merge_duplication, :bib, :file)).to eq :bib1
      end

      it "has changed transposed relation" do
        expect(subject).to receive(:update_link).with(:bib, :bib2).and_return false
        expect(subject).to receive(:transposed_relation).with(:bib, :bib2).and_return [:bib1, :bib2, true]
        expect(subject).to receive(:add_contributor).with(:bib1, :bib2).and_return false
        expect(subject.send(:merge_duplication, :bib, :file)).to eq :bib1
      end

      it "has changed contributor" do
        expect(subject).to receive(:update_link).with(:bib, :bib2).and_return false
        expect(subject).to receive(:transposed_relation).with(:bib, :bib2).and_return [:bib1, :bib2, false]
        expect(subject).to receive(:add_contributor).with(:bib1, :bib2).and_return true
        expect(subject.send(:merge_duplication, :bib, :file)).to eq :bib1
      end
    end

    context "update link" do
      let(:bib_with_link) { Relaton3gpp::BibliographicItem.new link: ["link"] }
      let(:bib_without_link) { Relaton3gpp::BibliographicItem.new link: [] }

      it "update original link" do
        expect(subject.send(:update_link, bib_with_link, bib_without_link)).to be true
        expect(bib_with_link.link.size).to eq 1
      end

      it "update new link" do
        expect(subject.send(:update_link, bib_without_link, bib_with_link)).to be true
        expect(bib_without_link.link.size).to eq 1
      end

      context "no changes" do
        it "both has link" do
          expect(subject.send(:update_link, bib_with_link, bib_with_link)).to be false
        end

        it "both empty" do
          expect(subject.send(:update_link, bib_without_link, bib_without_link)).to be false
        end
      end
    end

    context "transposed relation" do
      it "no dates" do
        bib = double("bib", date: [])
        bib2 = double("bib2", date: [])
        expect(subject.send(:transposed_relation, bib, bib2)).to eq [bib, bib2, false]
      end

      it "new doc has no date" do
        bib = double("bib", date: [])
        bib2 = double("bib2", date: [double("date", on: Date.today)])
        expect(subject.send(:transposed_relation, bib, bib2)).to eq [bib2, bib, true]
      end

      it "existing doc has no date" do
        bib = double("bib", date: [double("date", on: Date.today)])
        bib2 = double("bib2", date: [])
        expect(subject.send(:transposed_relation, bib, bib2)).to eq [bib, bib2, false]
      end

      it "both have dates" do
        bib = double("bib", date: [double("date", on: Date.today)])
        bib2 = double("bib2", date: [double("date", on: Date.today)])
        expect(subject).to receive(:check_transposed_date).with(bib, bib2).and_return [bib, bib2, false]
        expect(subject.transposed_relation(bib, bib2)).to eq [bib, bib2, false]
      end
    end

    context "check transposed date" do
      it "new doc is older" do
        bib = double("bib", date: [double("date", on: Date.today - 1)])
        bib2 = double("item", date: [double("date", on: Date.today)])
        expect(subject).to receive(:add_transposed_relation).with(bib, bib2)
        expect(subject.check_transposed_date(bib, bib2)).to eq [bib, bib2, true]
      end

      it "new doc is newer" do
        bib = double("bib", date: [double("date", on: Date.today)])
        bib2 = double("item", date: [double("date", on: Date.today - 1)])
        expect(subject).to receive(:add_transposed_relation).with(bib2, bib)
        expect(subject.check_transposed_date(bib, bib2)).to eq [bib2, bib, true]
      end

      it "dates are equal" do
        bib = double("bib", date: [double("date", on: Date.today)])
        bib2 = double("item", date: [double("date", on: Date.today)])
        expect(subject.check_transposed_date(bib, bib2)).to eq [bib, bib2, false]
      end
    end

    it "add transposed relation" do
      bib = Relaton3gpp::BibliographicItem.new
      bib2 = Relaton3gpp::BibliographicItem.new
      subject.add_transposed_relation(bib, bib2)
      expect(bib.relation.first.bibitem).to eq bib2
    end

    context "add contributor" do
      it "new doc has a different contributor" do
        surname = RelatonBib::LocalizedString.new "Doe"
        forename = RelatonBib::Forename.new content: "John"
        name = RelatonBib::FullName.new surname: surname, forename: [forename]
        person = RelatonBib::Person.new name: name
        contrib = RelatonBib::ContributionInfo.new entity: person
        bib = Relaton3gpp::BibliographicItem.new contributor: [contrib]

        surname2 = RelatonBib::LocalizedString.new "Smith"
        forename2 = RelatonBib::Forename.new content: "John"
        name2 = RelatonBib::FullName.new surname: surname2, forename: [forename2]
        person2 = RelatonBib::Person.new name: name2
        contrib2 = RelatonBib::ContributionInfo.new entity: person2
        bib2 = Relaton3gpp::BibliographicItem.new contributor: [contrib2]

        expect(subject.add_contributor(bib, bib2)).to be true
        expect(bib.contributor.size).to eq 2
        expect(bib.contributor[0]).to be contrib
        expect(bib.contributor[1]).to be contrib2
      end

      it "new doc has the same contributor with different affiliation" do
        surname = RelatonBib::LocalizedString.new "Doe"
        forename = RelatonBib::Forename.new content: "John"
        name = RelatonBib::FullName.new surname: surname, forename: [forename]
        person = RelatonBib::Person.new name: name
        contrib = RelatonBib::ContributionInfo.new entity: person
        bib = Relaton3gpp::BibliographicItem.new contributor: [contrib]

        org = RelatonBib::Organization.new name: "Org"
        aff = RelatonBib::Affiliation.new organization: org
        surname2 = RelatonBib::LocalizedString.new "Doe"
        forename2 = RelatonBib::Forename.new content: "John"
        name2 = RelatonBib::FullName.new surname: surname2, forename: [forename2]
        person2 = RelatonBib::Person.new name: name2, affiliation: [aff]
        contrib2 = RelatonBib::ContributionInfo.new entity: person2
        bib2 = Relaton3gpp::BibliographicItem.new contributor: [contrib2]

        expect(subject.add_contributor(bib, bib2)).to be true
        expect(bib.contributor.size).to eq 1
        expect(bib.contributor[0]).to be contrib
        expect(bib.contributor[0].entity.affiliation.size).to eq 1
      end

      it "new doc has the same contributor with the same affiliation" do
        surname = RelatonBib::LocalizedString.new "Doe"
        forename = RelatonBib::Forename.new content: "John"
        name = RelatonBib::FullName.new surname: surname, forename: [forename]
        org = RelatonBib::Organization.new name: "Org"
        aff = RelatonBib::Affiliation.new organization: org
        person = RelatonBib::Person.new name: name, affiliation: [aff]
        contrib = RelatonBib::ContributionInfo.new entity: person
        bib = Relaton3gpp::BibliographicItem.new contributor: [contrib]

        surname2 = RelatonBib::LocalizedString.new "Doe"
        forename2 = RelatonBib::Forename.new content: "John"
        name2 = RelatonBib::FullName.new surname: surname2, forename: [forename2]
        org2 = RelatonBib::Organization.new name: "Org"
        aff2 = RelatonBib::Affiliation.new organization: org2
        person2 = RelatonBib::Person.new name: name2, affiliation: [aff2]
        contrib2 = RelatonBib::ContributionInfo.new entity: person2
        bib2 = Relaton3gpp::BibliographicItem.new contributor: [contrib2]

        expect(subject.add_contributor(bib, bib2)).to be false
        expect(bib.contributor.size).to eq 1
        expect(bib.contributor[0]).to be contrib
        expect(bib.contributor[0].entity.affiliation.size).to eq 1
      end

      it "skip organization" do
        org = RelatonBib::Organization.new name: "Org"
        contrib = RelatonBib::ContributionInfo.new entity: org
        bib = Relaton3gpp::BibliographicItem.new contributor: [contrib]

        org2 = RelatonBib::Organization.new name: "Org"
        contrib2 = RelatonBib::ContributionInfo.new entity: org2
        bib2 = Relaton3gpp::BibliographicItem.new contributor: [contrib2]

        expect(subject.add_contributor(bib, bib2)).to be false
        expect(bib.contributor.size).to eq 1
        expect(bib.contributor[0]).to be contrib
      end
    end
  end

  # it do
  #   Relaton3gpp::DataFetcher.fetch
  # end
end
