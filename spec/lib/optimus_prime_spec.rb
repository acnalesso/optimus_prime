require "optimus_prime"

describe OptimusPrime do

  let(:op) { OptimusPrime::Base.new }

  it "primes an endpoint" do
    expect( op.prime("test").status ).to eq 200
  end

  it "primes an endpoint with attributes" do
    op.prime("test", "I am a response")

    expect( op.get("test") ).to eq "I am a response"
  end

  it "sets a content type" do
    op.prime("test", "I am a response", content_type: :json)

    op.get("test") do |response|
      expect( response.headers["content-type"] ).to eq "application/json"
    end
  end

  context "Starting and Stopping the server" do
    it "starts the server" do
      OptimusPrime.restart_server
      expect( `ls ./tmp/pids` ).to include("optimus_prime.pid")
    end

    it "stops the server" do
      OptimusPrime.start_server
      OptimusPrime.stop_server
      expect( `ls ./tmp/pids` ).to_not include("optimus_prime.pid")
      OptimusPrime.start_server
    end

    it "informs me if the server is already running" do
      OptimusPrime.start_server
      expect( OptimusPrime.start_server ).to include("Optimus is already priming :)")
    end

  end

end
