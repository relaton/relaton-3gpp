require "relaton/3gpp/parser"

describe Relaton::ThreeGpp::Parser do
  it "parses a 3GPP document" do
    row = CSV::Row.new(
      [
        "Spec number",
        "Title",
        "Link",
        "Version",
        "Date",
        "Is TS",
        "Last Name",
        "First Name",
        "Organisation",
        "Responsible Primary",
        "Responsible Secondary",
        "Release",
        "WPM Code 2G",
        "WPM Code 3G",
        "Stage 1 Freeze",
        "Stage 2 Freeze",
        "Stage 3 Freeze",
        "Close Meeting",
        "Project Start",
        "Project End",
      ],
      [
        "02.09",
        "Security aspects",
        "https://www.3gpp.org/ftp/Specs/archive/02_series/02.09/0209-800.zip",
        "8.0.0",
        "Jun 30 2000 12:00AM",
        "1",
        "Christoffersson",
        "Per",
        "TeliaSonera AB",
        "S3",
        "S1, CP",
        "Release 1999",
        "GSM_Release_99",
        "3G_R1999",
        "SA-#6",
        "SA-#6",
        "SA-#6",
        "SA#40",
        "Nov  1 1996 12:00AM",
        "Dec 17 1999 12:00AM",
      ]
    )
    item = described_class.parse(row)
    expect(item).to be_a(Relaton::Bib::ItemData)
    expect(item.id).to eq("3GPPTS0209REL99800")
    expect(item.type).to eq("standard")
    expect(item.language).to eq(["en"])
    expect(item.script).to eq(["Latn"])
    expect(item.title[0].content).to eq("Security aspects")
    expect(item.source[0].content).to eq("https://www.3gpp.org/ftp/Specs/archive/02_series/02.09/0209-800.zip")
    expect(item.docidentifier[0].content).to eq("3GPP TS 02.09:REL-99/8.0.0")
    expect(item.docnumber).to eq("TS 02.09:REL-99/8.0.0")
    expect(item.date[0].at.to_s).to eq("2000-06-30")
    expect(item.version[0].draft).to eq("8.0.0")
    expect(item.contributor[0].role[0].type).to eq("author")
    expect(item.contributor[0].role[1].type).to eq("publisher")
    expect(item.contributor[0].organization.name[0].content).to eq("3rd Generation Partnership Project")
    expect(item.contributor[0].organization.abbreviation.content).to eq("3GPP")
    expect(item.contributor[0].organization.address[0].street[0]).to eq("c/o ETSI 650, route des Lucioles")
    expect(item.contributor[1].role[0].type).to eq("author")
    expect(item.contributor[1].person.name.forename[0].content).to eq("Per")
    expect(item.contributor[1].person.name.surname.content).to eq("Christoffersson")
    expect(item.contributor[1].person.affiliation[0].organization.name[0].content).to eq("TeliaSonera AB")
    expect(item.place[0].formatted_place).to eq("Sophia Antipolis Cedex, France")
    expect(item.ext.doctype.content).to eq("TS")
    expect(item.contributor[2].role[0].type).to eq("author")
    expect(item.contributor[2].role[0].description[0].content).to eq("committee")
    expect(item.contributor[2].organization.subdivision[0].name[0].content).to eq("S3")
    expect(item.contributor[2].organization.subdivision[0].type).to eq("technical-committee")
    expect(item.contributor[2].organization.subdivision[0].subtype).to eq("prime")
    expect(item.contributor[3].organization.subdivision[0].name[0].content).to eq("S1")
    expect(item.contributor[3].organization.subdivision[0].subtype).to eq("other")
    expect(item.contributor[4].organization.subdivision[0].name[0].content).to eq("CP")
    expect(item.contributor[4].organization.subdivision[0].subtype).to eq("other")
    expect(item.ext.flavor).to eq("3gpp")
    expect(item.ext.radiotechnology).to eq("3G")
    expect(item.ext.release.wpm_code_2g).to eq("GSM_Release_99")
    expect(item.ext.release.wpm_code_3g).to eq("3G_R1999")
    expect(item.ext.release.freeze_stage1_meeting).to eq("SA-#6")
    expect(item.ext.release.freeze_stage2_meeting).to eq("SA-#6")
    expect(item.ext.release.freeze_stage3_meeting).to eq("SA-#6")
    expect(item.ext.release.close_meeting).to eq("SA#40")
    expect(item.ext.release.project_start.to_s).to eq("1996-11-01")
    expect(item.ext.release.project_end.to_s).to eq("1999-12-17")
  end

  context "#release" do
    it "Ph number" do
      row = CSV::Row.new(["Release", "WPM Code 2G"], ["Phase 2", "GSM_PH2"])
      parser = described_class.new(row, {})
      expect(parser.release).to eq("Ph2")
    end

    it "Release" do
      row = CSV::Row.new(["Release", "WPM Code 2G"], ["UMTS", ""])
      parser = described_class.new(row, {})
      expect(parser.release).to eq("UMTS")
    end
  end

  context "errors tracking" do
    let(:errors) { Hash.new(true) }
    let(:full_headers) do
      %w[Spec\ number Title Link Version Date Is\ TS Last\ Name First\ Name
         Organisation Responsible\ Primary Responsible\ Secondary Release
         WPM\ Code\ 2G WPM\ Code\ 3G Stage\ 1\ Freeze Stage\ 2\ Freeze
         Stage\ 3\ Freeze Close\ Meeting Project\ Start Project\ End]
    end
    let(:full_values) do
      ["02.09", "Security aspects",
       "https://www.3gpp.org/ftp/Specs/archive/02_series/02.09/0209-800.zip",
       "8.0.0", "Jun 30 2000 12:00AM", "1", "Doe", "John", "ACME",
       "S3", "S1, CP", "Release 1999", "GSM_Release_99", "3G_R1999",
       "SA-#6", "SA-#6", "SA-#6", "SA#40",
       "Nov  1 1996 12:00AM", "Dec 17 1999 12:00AM"]
    end

    it "sets error flags to false when all fields are present" do
      row = CSV::Row.new(full_headers, full_values)
      described_class.parse(row, errors)
      %i[title source docid version release date contributor
         editorial_group_contributor_prime editorial_group_contributor_other
         contributor_person_surname contributor_person_forename
         contributor_person_affiliation radiotechnology
         wmp_code_2g wmp_code_3g freeze_stage1_meeting freeze_stage2_meeting
         freeze_stage3_meeting close_meeting project_start project_end].each do |key|
        expect(errors[key]).to be(false), "expected errors[:#{key}] to be false"
      end
    end

    it "keeps error flags true when fields are missing" do
      row = CSV::Row.new(full_headers,
                         [nil, nil, nil, nil, nil, "1", nil, nil, nil, nil, "", nil, nil, nil,
                          nil, nil, nil, nil, nil, nil])
      described_class.parse(row, errors)
      %i[title source docid version date
         wmp_code_2g wmp_code_3g freeze_stage1_meeting freeze_stage2_meeting
         freeze_stage3_meeting close_meeting project_start project_end].each do |key|
        expect(errors[key]).to be(true), "expected errors[:#{key}] to be true"
      end
    end

    it "once false, stays false on subsequent missing-data rows" do
      good_row = CSV::Row.new(full_headers, full_values)
      described_class.parse(good_row, errors)

      bad_row = CSV::Row.new(full_headers,
                             [nil, nil, nil, nil, nil, "1", nil, nil, nil, nil, "", nil, nil, nil,
                              nil, nil, nil, nil, nil, nil])
      described_class.parse(bad_row, errors)

      %i[title source docid version radiotechnology
         wmp_code_2g wmp_code_3g freeze_stage1_meeting freeze_stage2_meeting
         freeze_stage3_meeting close_meeting project_start project_end].each do |key|
        expect(errors[key]).to be(false), "expected errors[:#{key}] to stay false after good row"
      end
    end
  end

  context "#parse_radiotechnology" do
    it "5G" do
      row = CSV::Row.new(["WPM Code 2G", "WPM Code 3G"], ["GSM_Release_99", "3G4G5G_Rel-15"])
      parser = described_class.new(row, {})
      expect(parser.parse_radiotechnology).to eq("5G")
    end

    it "4G" do
      row = CSV::Row.new(["WPM Code 2G", "WPM Code 3G"], ["GSM_Release_99", "3G4G_Rel-10"])
      parser = described_class.new(row, {})
      expect(parser.parse_radiotechnology).to eq("LTE")
    end

    it "2G" do
      row = CSV::Row.new(["WPM Code 2G", "WPM Code 3G"], ["GSM_Release_99", ""])
      parser = described_class.new(row, {})
      expect(parser.parse_radiotechnology).to eq("2G")
    end
  end
end
