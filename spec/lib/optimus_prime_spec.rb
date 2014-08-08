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

end
