RSpec.describe Relaton3gpp::Parser do
  it "create instance and run parsing" do
    parser = double "parser"
    expect(parser).to receive(:parse)
    expect(Relaton3gpp::Parser).to receive(:new).with(:row, :dbs).and_return(parser)
    Relaton3gpp::Parser.parse(:row, :dbs)
  end

  it "initialize parser" do
    dbs = double "dbs"
    spec = double "spec"
    expect(spec).to receive(:detect).and_yield({ Number: "00.00" }).and_return(:spec)
    expect(dbs).to receive(:[]).with("Specs_GSM+3G").and_return(spec)
    specrel = double "specrel"
    expect(specrel).to receive(:detect).and_yield({ Spec: "00.00", Release: "R00" }).and_return(:specrel)
    expect(dbs).to receive(:[]).with("Specs_GSM+3G_release-info").and_return(specrel)
    rel = double "rel"
    expect(rel).to receive(:detect).and_yield({ Release_code: "R00" }).and_return(:rel)
    expect(dbs).to receive(:[]).with("Releases").and_return(rel)
    row = { spec: "00.00", release: "R00" }
    subj = Relaton3gpp::Parser.new row, dbs
    expect(subj.instance_variable_get(:@row)).to be row
    expect(subj.instance_variable_get(:@spec)).to eq :spec
    expect(subj.instance_variable_get(:@specrel)).to eq :specrel
    expect(subj.instance_variable_get(:@rel)).to eq :rel
  end

  it "skip parsing doc" do
    parser = Relaton3gpp::Parser.new({}, { "Specs_GSM+3G" => [] })
    expect(parser.parse).to be_nil
  end

  context "instance" do
    subject do
      row = {
        spec: "00.00", release: "R00", location: "get it#http://example.com#",
        MAJOR_VERSION_NB: "1", TECHNICAL_VERSION_NB: "2", EDITORIAL_VERSION_NB: "3",
        completed: "2005-03-22 10:24:10", comment: "Comment"
      }
      dbs = {
        "Specs_GSM+3G" => [{
          Number: "00.00", Title: "Title", description: "Abstract",
          "title verified": "2002-02-06 15:46:51", "WG prime": "WG1",
          "WG other": "WG2", "former WG": "WG3", "For publication": "1",
          "2g": "1", "3g": "0", LTE: "0", "5g": "0"
        }],
        "Specs_GSM+3G_release-info" => [{
          Spec: "00.00", Release: "R00", remarks: "Remarks", withdrawn: "1"
        }],
        "Releases" => [{
          Release_code: "R00", "rel-proj-start": "1999-01-01 00:00:00",
          "rel-proj-end": "1999-12-17 00:00:00", version_2g: "2", version_3g: "3",
          defunct: "1", wpm_code_2g: "GSM_Release_99", wpm_code_3g: "3G_R1999",
          "freeze meeting": "SP-06", Stage1_freeze: "SP-06", Stage2_freeze: "SP-06",
          Stage3_freeze: "SP-06", Closed: "SP-40"
        }],
      }
      Relaton3gpp::Parser.new(row, dbs)
    end

    it "parse doc" do
      expect(subject).to receive(:parse_title)
      expect(subject).to receive(:parse_link)
      expect(subject).to receive(:parse_abstract)
      expect(subject).to receive(:parse_docid)
      expect(subject).to receive(:parse_date)
      expect(subject).to receive(:parse_editorialgroup)
      expect(subject).to receive(:parse_note)
      expect(subject).to receive(:parse_status)
      expect(subject).to receive(:parse_radiotechnology)
      expect(subject).to receive(:parse_release)
      expect(Relaton3gpp::BibliographicItem).to receive(:new).and_return(:bibitem)
      expect(subject.parse).to be :bibitem
    end

    it "parse title" do
      title = subject.parse_title
      expect(title).to be_instance_of RelatonBib::TypedTitleStringCollection
      expect(title.first).to be_instance_of RelatonBib::TypedTitleString
      expect(title.first.title.content).to eq "Title"
    end

    it "parse link" do
      link = subject.parse_link
      expect(link).to be_instance_of Array
      expect(link.first).to be_instance_of RelatonBib::TypedUri
      expect(link.first.content.to_s).to eq "http://example.com"
    end

    it "parse abstract" do
      abstract = subject.parse_abstract
      expect(abstract).to be_instance_of Array
      expect(abstract.first).to be_instance_of RelatonBib::FormattedString
      expect(abstract.first.content).to eq "Abstract"
    end

    it "parse docid" do
      docid = subject.parse_docid
      expect(docid).to be_instance_of Array
      expect(docid.first).to be_instance_of RelatonBib::DocumentIdentifier
      expect(docid.size).to eq 2
      expect(docid.first.id).to eq "3GPP  00.00:R00/1.2.3"
    end

    it "parse date" do
      date = subject.parse_date
      expect(date).to be_instance_of Array
      expect(date.first).to be_instance_of RelatonBib::BibliographicDate
      expect(date.size).to eq 2
      expect(date.first.on).to eq "2005-03-22"
    end

    it "parse editorialgroup" do
      edg = subject.parse_editorialgroup
      expect(edg).to be_instance_of RelatonBib::EditorialGroup
      expect(edg.technical_committee.size).to eq 3
      expect(edg.technical_committee.first.workgroup.name).to eq "WG1"
    end

    it "parse note" do
      note = subject.parse_note
      expect(note).to be_instance_of RelatonBib::BiblioNoteCollection
      expect(note.size).to eq 2
      expect(note.first).to be_instance_of RelatonBib::BiblioNote
      expect(note.first.type).to eq "remark"
      expect(note.first.content).to eq "Remarks"
    end

    context "parse status" do
      it "withdrawn" do
        status = subject.parse_status
        expect(status).to be_instance_of RelatonBib::DocumentStatus
        expect(status.stage.value).to eq "withdrawn"
      end

      it "published" do
        subject.instance_variable_get(:@specrel)[:withdrawn] = "0"
        status = subject.parse_status
        expect(status).to be_instance_of RelatonBib::DocumentStatus
        expect(status.stage.value).to eq "published"
      end
    end

    context "parse radiotechnology" do
      it "2g" do
        expect(subject.parse_radiotechnology).to eq "2G"
      end

      it "3g" do
        subject.instance_variable_get(:@spec)[:"2g"] = "0"
        subject.instance_variable_get(:@spec)[:"3g"] = "1"
        expect(subject.parse_radiotechnology).to eq "3G"
      end

      it "LTE" do
        subject.instance_variable_get(:@spec)[:"2g"] = "0"
        subject.instance_variable_get(:@spec)[:LTE] = "1"
        expect(subject.parse_radiotechnology).to eq "LTE"
      end

      it "5g" do
        subject.instance_variable_get(:@spec)[:"2g"] = "0"
        subject.instance_variable_get(:@spec)[:"5G"] = "1"
        expect(subject.parse_radiotechnology).to eq "5G"
      end
    end

    it "parse release" do
      release = subject.parse_release
      expect(release).to be_instance_of Relaton3gpp::Release
      expect(release.instance_variable_get(:@version2g)).to eq "2"
      expect(release.instance_variable_get(:@version3g)).to eq "3"
      expect(release.instance_variable_get(:@defunct)).to be true
      expect(release.instance_variable_get(:@wpm_code_2g)).to eq "GSM_Release_99"
      expect(release.instance_variable_get(:@wpm_code_3g)).to eq "3G_R1999"
      expect(release.instance_variable_get(:@freeze_meeting)).to eq "SP-06"
      expect(release.instance_variable_get(:@freeze_stage1_meeting)).to eq "SP-06"
      expect(release.instance_variable_get(:@freeze_stage2_meeting)).to eq "SP-06"
      expect(release.instance_variable_get(:@freeze_stage3_meeting)).to eq "SP-06"
      expect(release.instance_variable_get(:@close_meeting)).to eq "SP-40"
      expect(release.instance_variable_get(:@project_start)).to eq "1999-01-01"
      expect(release.instance_variable_get(:@project_end)).to eq "1999-12-17"
    end
  end
end
