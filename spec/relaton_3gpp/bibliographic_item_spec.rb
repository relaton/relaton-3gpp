RSpec.describe Relaton3gpp::BibliographicItem do
  it "warn if invalid radiotechnology type" do
    expect do
      Relaton3gpp::BibliographicItem.new(radiotechnology: "invalid")
    end.to output(/\[relaton-3gpp\] WARN: Unknown radiotechnology type: `invalid`/).to_stderr_from_any_process
  end

  it "warn if invalid doctype" do
    expect do
      Relaton3gpp::BibliographicItem.new(doctype: Relaton3gpp::DocumentType.new(type: "invalid"))
    end.to output(/\[relaton-3gpp\] WARN: Unknown doctype: `invalid`/).to_stderr_from_any_process
  end

  it "warn if doctype is missing" do
    expect do
      Relaton3gpp::BibliographicItem.new
    end.to output(/\[relaton-3gpp\] WARN: Doctype is missing/).to_stderr_from_any_process
  end

  it "warn if invalid docsubtype" do
    expect do
      Relaton3gpp::BibliographicItem.new(docsubtype: "invalid")
    end.to output(/\[relaton-3gpp\] WARN: Unknown docsubtype: `invalid`/).to_stderr_from_any_process
  end
end
