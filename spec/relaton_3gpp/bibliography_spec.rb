RSpec.describe Relaton3gpp::Bibliography do
  it "raise RequestError" do
    expect(Relaton::Index).to receive(:find_or_create).and_raise(Timeout::Error)
    expect { Relaton3gpp::Bibliography.get("ref") }.to raise_error(RelatonBib::RequestError)
  end
end
