require "csv"

RSpec.describe Relaton3gpp::Parser do
  it "create instance and run parsing" do
    parser = double "parser"
    expect(parser).to receive(:parse)
    expect(Relaton3gpp::Parser).to receive(:new).with(:row).and_return(parser)
    Relaton3gpp::Parser.parse(:row)
  end

  it "initialize parser" do
    subj = Relaton3gpp::Parser.new :row
    expect(subj.instance_variable_get(:@row)).to be :row
  end

  # it "skip parsing doc" do
  #   parser = Relaton3gpp::Parser.new({})
  #   expect(parser.parse).to be_nil
  # end

  context "instance" do
    let(:row) do
      CSV.parse(<<~CSV, headers: true, col_sep: ";").first
        Spec number;Title;Link;Version;Date;Is TS;Last Name;First Name;Organisation;Responsible Primary;Responsible Secondary;Release;WPM Code 2G;WPM Code 3G;Stage 1 Freeze;Stage 2 Freeze;Stage 3 Freeze;Close Meeting;Project Start;Project End
        00.00;Title;http://example.com;3.1.0;Nov 18 1994 12:00AM;1;Rapeli;Juha;Org;SP;R6, CP;UMTS;GSM_Release_99;;SA#47;SA#49;SA#51;SA#65;Aug 18 1994 12:00AM;Feb 12 1999 12:00AM
      CSV
    end

    subject { Relaton3gpp::Parser.new(row) }

    context "parse doc" do
      let(:doc) { subject.parse }
      it { expect(doc).to be_instance_of Relaton3gpp::BibliographicItem }
      it { expect(doc.title).to be_instance_of RelatonBib::TypedTitleStringCollection }
      it { expect(doc.title.first).to be_instance_of RelatonBib::TypedTitleString }
      it { expect(doc.link.first).to be_instance_of RelatonBib::TypedUri }
      it { expect(doc.docidentifier.first).to be_instance_of RelatonBib::DocumentIdentifier }
      it { expect(doc.docnumber).to eq "TS 00.00:REL-99/3.1.0" }
      it { expect(doc.date.first).to be_instance_of RelatonBib::BibliographicDate }
      it { expect(doc.doctype).to be_instance_of Relaton3gpp::DocumentType }
      it { expect(doc.editorialgroup).to be_instance_of RelatonBib::EditorialGroup }
      it { expect(doc.version.first).to be_instance_of RelatonBib::BibliographicItem::Version }
      it { expect(doc.radiotechnology).to eq "2G" }
      it { expect(doc.release).to be_instance_of Relaton3gpp::Release }
      it { expect(doc.contributor.first).to be_instance_of RelatonBib::ContributionInfo }
      it { expect(doc.place.first).to be_instance_of RelatonBib::Place }
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
      expect(link.first.type).to eq "src"
    end

    # it "parse abstract" do
    #   abstract = subject.parse_abstract
    #   expect(abstract).to be_instance_of Array
    #   expect(abstract.first).to be_instance_of RelatonBib::FormattedString
    #   expect(abstract.first.content).to eq "Abstract"
    # end

    it "parse docid" do
      docid = subject.parse_docid
      expect(docid).to be_instance_of Array
      expect(docid.first).to be_instance_of RelatonBib::DocumentIdentifier
      expect(docid.size).to eq 1
      expect(docid.first.id).to eq "3GPP TS 00.00:REL-99/3.1.0"
      expect(docid.first.type).to eq "3GPP"
      expect(docid.first.primary).to be true
    end

    context "release" do
      it do
        row["WPM Code 2G"] = nil
        expect(subject.release).to eq "UMTS"
      end

      it "number" do
        row["WPM Code 2G"] = "GSM_Release_99"
        expect(subject.release).to eq "REL-99"
      end

      it "phase" do
        row["WPM Code 2G"] = "GSM_PH2"
        expect(subject.release).to eq "Ph2"
      end
    end

    it "parse date" do
      date = subject.parse_date
      expect(date).to be_instance_of Array
      expect(date.first).to be_instance_of RelatonBib::BibliographicDate
      expect(date.size).to eq 1
      expect(date.first.on).to eq "1994-11-18"
      expect(date.first.type).to eq "published"
    end

    it "parse editorialgroup" do
      edg = subject.parse_editorialgroup
      expect(edg).to be_instance_of RelatonBib::EditorialGroup
      expect(edg.technical_committee.size).to eq 3
      expect(edg.technical_committee.first.workgroup.name).to eq "SP"
    end

    it "parse version" do
      ver = subject.parse_version
      expect(ver).to be_instance_of Array
      expect(ver.first).to be_instance_of RelatonBib::BibliographicItem::Version
      expect(ver.first.draft).to eq "3.1.0"
    end

    it "parse doctype" do
      doctype = subject.parse_doctype
      expect(doctype).to be_instance_of Relaton3gpp::DocumentType
      # expect(doctype.type).to eq "Technical Specification"
      expect(doctype.type).to eq "TS"
    end

    # it "parse note" do
    #   note = subject.parse_note
    #   expect(note).to be_instance_of RelatonBib::BiblioNoteCollection
    #   expect(note.size).to eq 2
    #   expect(note.first).to be_instance_of RelatonBib::BiblioNote
    #   expect(note.first.type).to eq "remark"
    #   expect(note.first.content).to eq "Remarks"
    # end

    # context "parse status" do
    #   it "withdrawn" do
    #     status = subject.parse_status
    #     expect(status).to be_instance_of RelatonBib::DocumentStatus
    #     expect(status.stage.value).to eq "withdrawn"
    #   end

    #   it "published" do
    #     subject.instance_variable_get(:@specrel)[:withdrawn] = "0"
    #     status = subject.parse_status
    #     expect(status).to be_instance_of RelatonBib::DocumentStatus
    #     expect(status.stage.value).to eq "published"
    #   end
    # end

    context "parse radiotechnology" do
      it "empty" do
        row["WPM Code 2G"] = nil
        expect(subject.parse_radiotechnology).to be_nil
      end

      it "2g" do
        expect(subject.parse_radiotechnology).to eq "2G"
      end

      it "3g" do
        row["WPM Code 3G"] = "3G_R1999"
        expect(subject.parse_radiotechnology).to eq "3G"
      end

      it "LTE" do
        row["WPM Code 3G"] = "3G4G_Rel-10"
        expect(subject.parse_radiotechnology).to eq "LTE"
      end

      it "5g" do
        row["WPM Code 3G"] = "3G4G5G_Rel-15"
        expect(subject.parse_radiotechnology).to eq "5G"
      end
    end

    it "parse release" do
      row["WPM Code 2G"] = "GSM_Release_99"
      row["WPM Code 3G"] = "3G_R1999"
      release = subject.parse_release
      expect(release).to be_instance_of Relaton3gpp::Release
      # expect(release.instance_variable_get(:@version2g)).to eq "2"
      # expect(release.instance_variable_get(:@version3g)).to eq "3"
      # expect(release.instance_variable_get(:@defunct)).to be true
      expect(release.instance_variable_get(:@wpm_code_2g)).to eq "GSM_Release_99"
      expect(release.instance_variable_get(:@wpm_code_3g)).to eq "3G_R1999"
      # expect(release.instance_variable_get(:@freeze_meeting)).to eq "SP-06"
      expect(release.instance_variable_get(:@freeze_stage1_meeting)).to eq "SA#47"
      expect(release.instance_variable_get(:@freeze_stage2_meeting)).to eq "SA#49"
      expect(release.instance_variable_get(:@freeze_stage3_meeting)).to eq "SA#51"
      expect(release.instance_variable_get(:@close_meeting)).to eq "SA#65"
      expect(release.instance_variable_get(:@project_start)).to eq "1994-08-18"
      expect(release.instance_variable_get(:@project_end)).to eq "1999-02-12"
    end

    it "parse contributor" do
      contrib = subject.parse_contributor
      expect(contrib).to be_instance_of Array
      expect(contrib[0]).to be_instance_of RelatonBib::ContributionInfo
      expect(contrib[0].role[0].type).to eq "author"
      expect(contrib[0].role[1].type).to eq "publisher"
      expect(contrib[0].entity).to be_instance_of RelatonBib::Organization
      expect(contrib[0].entity.name[0].content).to eq "3rd Generation Partnership Project"
      expect(contrib[0].entity.abbreviation.content).to eq "3GPP"
      expect(contrib[0].entity.contact[0].country).to eq "France"
      expect(contrib[0].entity.contact[0].street).to eq(
        ["c/o ETSI 650, route des Lucioles", "3GPP Mobile Competence Centre"],
      )
      expect(contrib[0].entity.contact[0].city).to eq "Sophia Antipolis Cedex"
      expect(contrib[0].entity.contact[0].postcode).to eq "06921"
      expect(contrib[1].role[0].type).to eq "author"
      expect(contrib[1].entity).to be_instance_of RelatonBib::Person
      expect(contrib[1].entity.name.surname.content).to eq "Rapeli"
      expect(contrib[1].entity.name.forename[0].content).to eq "Juha"
      expect(contrib[1].entity.affiliation[0].organization.name[0].content).to eq "Org"
    end
  end
end
