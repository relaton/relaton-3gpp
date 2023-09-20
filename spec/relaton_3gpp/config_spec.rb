describe Relaton3gpp do
  after { Relaton3gpp.instance_variable_set :@configuration, nil }

  it "configure" do
    Relaton3gpp.configure do |conf|
      conf.logger = :logger
    end
    expect(Relaton3gpp.configuration.logger).to eq :logger
  end
end
