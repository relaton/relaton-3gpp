RSpec.describe Relaton3gpp::XMLParser do
  it "parse documet" do
    xml = File.read "spec/fixtures/bibdata.xml", encoding: "UTF-8"
    bib = Relaton3gpp::XMLParser.from_xml xml
    expect(bib.to_xml(bibdata: true)).to be_equivalent_to xml
  end
end
