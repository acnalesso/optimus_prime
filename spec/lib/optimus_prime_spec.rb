describe OptimusPrime do

  let(:op) { OptimusPrime::Base.new }

  it "primes an endpoint" do
    expect( op.prime("test").status ).to eq 201
  end

  it "primes an endpoint with attributes" do
    op.prime("test", "I am a response")

    response = ::Faraday.get("http://localhost:7002/get/test")
    expect( response.body ).to eq "I am a response"
  end

  it "sets a content type" do
    op.prime("test", "I am a response", content_type: :json)

    response = ::Faraday.get("http://localhost:7002/get/test")
    expect( response.headers["content-type"] ).to eq "application/json"
  end

  it "retrieves a path containing attributes" do
    op.prime("route/name", "<html><head><title>Response</title></head><body><h1>Hi</h1><body></html>", content_type: :html)
    response = ::Faraday.get('http://localhost:7002/get/route/name')

    expect(response.headers["content-type"]).to include("text/html")
    expect(response.body).to include("<h1>Hi</h1>")
  end

  it "retrieves a very nested path" do
    op.prime("getUserProfile/queue/token/12345678", { username: 'Antonio', age: 21 }.to_json, content_type: :json)
    response = ::Faraday.get('http://localhost:7002/get/getUserProfile/queue/token/12345678')

    expect(JSON.parse(response.body)).to eq({ "username" => "Antonio", "age" => 21 })
  end

  it "retrieves from url with params" do
    op.prime("getUser?id=10&queue=NaN", { username: "Test" }.to_json, content_type: :json)
    response = ::Faraday.get('http://localhost:7002/get/getUser?id=10&queue=NaN')

    expect( JSON.parse(response.body) ).to eq({ "username" => "Test" })
  end

  it "returns a 404 when endpoint is not found" do
    response = ::Faraday.get('http://localhost:7002/get/iDoNotExist')

    expect( response.status ).to eq 404
  end

  it "allows developers to change the response status code" do
    op.prime("notFound", { username: "Test" }.to_json, content_type: :json, status_code: 404)
    response = ::Faraday.get('http://localhost:7002/get/notFound')

    expect( response.status ).to eq 404
  end

  it "returns 200 http status code as default" do
    op.prime("continue", { username: "Test" }.to_json, content_type: :json)
    response = ::Faraday.get('http://localhost:7002/get/continue')

    expect( response.status ).to eq 200
  end

  it "handles POST requests" do
    op.prime("user", { username: "Test" }.to_json, content_type: :json)
    response = ::Faraday.post('http://localhost:7002/get/user')

    expect( JSON.parse(response.body) ).to eq({ "username" => "Test" })
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

  context "Asserting on request content" do

    it "returns a 404 if the request body does not match the assertion" do
      op.prime("user", { username: "Test" }.to_json, content_type: :json, constraint: "request.body.string.include?('ahahah')")

      response = ::Faraday.post('http://localhost:7002/get/user', "I am a body")

      expect( response.status ).to eq 404
    end

    it "returns a 200 if the request body does match the assertion" do
      op.prime("user", { username: "Test" }.to_json, content_type: :json, constraint: "request.body.string.include?('I am a body')")

      response = ::Faraday.post('http://localhost:7002/get/user', "I am a body")

      expect( response.status ).to eq 200
    end

  end

end
