describe Relaton3gpp::HashConverter do
  it "create 3GPP bib item from hash" do
    item = Relaton3gpp::HashConverter.bib_item title: [{ content: "title" }]
    expect(item).to be_instance_of Relaton3gpp::BibliographicItem
  end
end
