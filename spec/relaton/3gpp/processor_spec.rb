require "relaton/3gpp/processor"
require "relaton/3gpp/data_fetcher"

describe Relaton::ThreeGpp::Processor do
  it "#intialize" do
    expect(subject.instance_variable_get(:@short)).to eq :relaton_3gpp
    expect(subject.instance_variable_get(:@prefix)).to eq "3GPP"
    expect(subject.instance_variable_get(:@defaultprefix)).to eq %r{^3GPP\s}
    expect(subject.instance_variable_get(:@idtype)).to eq "3GPP"
    expect(subject.instance_variable_get(:@datasets)).to eq %w[status-smg-3GPP status-smg-3GPP-force]
  end

  it "#get" do
    expect(Relaton::ThreeGpp::Bibliography).to receive(:get).with("19115", "2014", {})
    subject.get "19115", "2014", {}
  end

  it "#fetch_data" do
    expect(Relaton::ThreeGpp::DataFetcher).to receive(:fetch).with("status-smg-3gpp", output: "output", format: "xml")
    subject.fetch_data "status-smg-3gpp", output: "output", format: "xml"
  end

  it "#from_xml" do
    expect(Relaton::ThreeGpp::Item).to receive(:from_xml).with("<xml></xml>")
    subject.from_xml "<xml></xml>"
  end

  it "#from_yaml" do
    expect(Relaton::ThreeGpp::Item).to receive(:from_yaml).with("---\nkey: value\n")
    subject.from_yaml "---\nkey: value\n"
  end

  it "#grammar_hash" do
    expect(subject.grammar_hash).to be_a String
  end

  it "#remove_index_file" do
    index = instance_double(Relaton::Index::Type)
    expect(index).to receive(:remove_file)
    expect(Relaton::Index).to receive(:find_or_create).with("3GPP", url: true, file: "index-v1.yaml").and_return index
    subject.remove_index_file
  end
end
