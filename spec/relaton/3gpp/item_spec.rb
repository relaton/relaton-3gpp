describe Relaton::ThreeGpp::Item do
  let(:input_yaml) { File.read "spec/fixtures/bibdata.yaml", encoding: "UTF-8" }
  let(:item) { described_class.from_yaml input_yaml }

  it "rounds trip" do
    input_hash = YAML.safe_load(input_yaml)
    output_yaml = Relaton::ThreeGpp::Item.to_yaml item
    output_hash = YAML.safe_load(output_yaml)
    expect(output_hash).to eq input_hash
  end
end
