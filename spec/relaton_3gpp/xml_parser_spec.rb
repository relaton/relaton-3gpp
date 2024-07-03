RSpec.describe Relaton3gpp::XMLParser do
  it "parse documet" do
    xml = File.read "spec/fixtures/bibdata.xml", encoding: "UTF-8"
    bib = Relaton3gpp::XMLParser.from_xml xml
    expect(bib.to_xml(bibdata: true)).to be_equivalent_to xml
  end

  it "creare_doctype" do
    doc = Nokogiri::XML("<type abbreviation='abbr'>type</type>").at "type"
    dt = Relaton3gpp::XMLParser.send :create_doctype, doc
    expect(dt).to be_instance_of Relaton3gpp::DocumentType
    expect(dt.type).to eq "type"
    expect(dt.abbreviation).to eq "abbr"
  end
end
