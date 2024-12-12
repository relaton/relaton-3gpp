describe Relaton3gpp::HashConverter do
  it "create 3GPP bib item from hash" do
    hash = YAML.load_file "spec/fixtures/bib.yaml"
    # item = Relaton3gpp::HashConverter.bib_item title: [{ content: "title" }]
    item = Relaton3gpp::BibliographicItem.from_hash hash
    expect(item).to be_instance_of Relaton3gpp::BibliographicItem
    expect(item.to_hash).to eq hash
  end
end
