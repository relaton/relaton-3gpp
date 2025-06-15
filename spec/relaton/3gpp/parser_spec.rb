describe Relaton::Bib::Parser do
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
    item = Relaton::ThreeGpp::Parser.parse(row)
    expect(item).to be_a(Relaton::Bib::ItemData)
    expect(item.type).to eq("standard")
    expect(item.language).to eq(["en"])
    expect(item.script).to eq(["Latn"])
    expect(item.title[0].content).to eq("Security aspects")
    expect(item.source[0].content).to eq("https://www.3gpp.org/ftp/Specs/archive/02_series/02.09/0209-800.zip")
    expect(item.docidentifier[0].content).to eq("3GPP TS 02.09:REL-99/8.0.0")
    expect(item.docnumber).to eq("TS 02.09:REL-99/8.0.0")
    expect(item.date[0].at).to eq("2000-06-30")
    expect(item.version[0].draft).to eq("8.0.0")
    expect(item.contributor[0].role[0].type).to eq("author")
    expect(item.contributor[0].role[1].type).to eq("publisher")
    expect(item.contributor[0].organization.name[0].content).to eq("3rd Generation Partnership Project")
    expect(item.contributor[0].organization.abbreviation.content).to eq("3GPP")
    expect(item.contributor[1].role[0].type).to eq("author")
    expect(item.contributor[1].person.name.forename[0].content).to eq("Per")
    expect(item.contributor[1].person.name.surname.content).to eq("Christoffersson")
    expect(item.contributor[1].person.affiliation[0].organization.name[0].content).to eq("TeliaSonera AB")
    expect(item.place[0].formatted_place).to eq("Sophia Antipolis Cedex, France")
    expect(item.ext.doctype.content).to eq("Technical Specification")
    expect(item.ext.editorialgroup.technical_committee[0].content).to eq("S3")
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
end
