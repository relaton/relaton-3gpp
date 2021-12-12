RSpec.describe Relaton3gpp::BibliographicItem do
  it "warn if invalid radiotechnology type" do
    expect do
      Relaton3gpp::BibliographicItem.new(radiotechnology: "invalid")
    end.to output(/Unknown radiotechnology type: invalid/).to_stderr
  end

  it "warn if invalid doctype" do
    expect do
      Relaton3gpp::BibliographicItem.new(doctype: "invalid")
    end.to output(/Unknown doctype: invalid/).to_stderr
  end

  it "warn if invalid docsubtype" do
    expect do
      Relaton3gpp::BibliographicItem.new(docsubtype: "invalid")
    end.to output(/Unknown docsubtype: invalid/).to_stderr
  end
end
