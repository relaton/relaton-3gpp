RSpec.describe Relaton::ThreeGpp::Item do
  it "raise RequestError" do
    expect(Relaton::Index).to receive(:find_or_create).and_raise(Timeout::Error)
    expect { Relaton::ThreeGpp::Bibliography.get("ref") }.to raise_error(Relaton::RequestError)
  end
end
