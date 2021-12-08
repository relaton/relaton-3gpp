# frozen_string_literal: true

RSpec.describe Relaton3gpp do
  it "has a version number" do
    expect(Relaton3gpp::VERSION).not_to be nil
  end

  it "returs grammar hash" do
    hash = Relaton3gpp.grammar_hash
    expect(hash).to be_instance_of String
    expect(hash.size).to eq 32
  end
end
