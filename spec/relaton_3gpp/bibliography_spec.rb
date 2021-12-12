RSpec.describe Relaton3gpp::Bibliography do
  it "raise RequestError" do
    expect(Net::HTTP).to receive(:get_response).and_raise(Timeout::Error)
    expect { Relaton3gpp::Bibliography.get("ref") }.to raise_error(RelatonBib::RequestError)
  end
end
