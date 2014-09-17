describe OptimusPrime do

  let(:op) { OptimusPrime::Base.new }

  it "primes an endpoint" do
    expect( op.prime("test").status ).to eq 201
  end

  it "primes an endpoint with attributes" do
    op.prime("test", "I am a response")

    response = ::Faraday.get("http://localhost:7003/get/test")
    expect( response.body ).to eq "I am a response"
  end

  it "sets a content type" do
    op.prime("test", "I am a response", content_type: :json)

    response = ::Faraday.get("http://localhost:7003/get/test")
    expect( response.headers["content-type"] ).to eq "application/json"
  end

  it "retrieves a path containing attributes" do
    op.prime("route/name", "<html><head><title>Response</title></head><body><h1>Hi</h1><body></html>", content_type: :html)
    response = ::Faraday.get('http://localhost:7003/get/route/name')

    expect(response.headers["content-type"]).to include("text/html")
    expect(response.body).to include("<h1>Hi</h1>")
  end

  it "retrieves a very nested path" do
    op.prime("getUserProfile/queue/token/12345678", { username: 'Antonio', age: 21 }.to_json, content_type: :json)
    response = ::Faraday.get('http://localhost:7003/get/getUserProfile/queue/token/12345678')

    expect(JSON.parse(response.body)).to eq({ "username" => "Antonio", "age" => 21 })
  end

  it "returns a 404 when endpoint is not found" do
    response = ::Faraday.get('http://localhost:7003/get/iDoNotExist')

    expect( response.status ).to eq 404
  end

  it "allows developers to change the response status code" do
    op.prime("notFound", { username: "Test" }.to_json, content_type: :json, status_code: 404)
    response = ::Faraday.get('http://localhost:7003/get/notFound')

    expect( response.status ).to eq 404
  end

  it "returns 200 http status code as default" do
    op.prime("continue", { username: "Test" }.to_json, content_type: :json)
    response = ::Faraday.get('http://localhost:7003/get/continue')

    expect( response.status ).to eq 200
  end


  context "Asserting on request content" do

    it "returns a 404 if the request body does not match the assertion" do
      op.prime("user", { username: "Test" }.to_json, content_type: :json, requested_with: "haha")

      response = ::Faraday.post('http://localhost:7003/get/user', "I am a body")

      expect( response.status ).to eq 404
    end

    it "returns a 200 if the request body does match the assertion" do
      op.prime("user", { username: "Test" }.to_json, content_type: :json, requested_with: "I am a body")

      response = ::Faraday.post('http://localhost:7003/get/user', "I am a body")

      expect( response.status ).to eq 200
    end

  end

  context "Server processing" do

    it "#GET tells the server to sleep for 10 seconds in order to reproduce timeouts" do
      op.prime("userAsleep", { username: "Test" }.to_json, content_type: :json, sleep: 10)

      f = ::Faraday.new('http://localhost:7003/get/')
      f.options.timeout = 0

      expect { f.get("/userAsleep") }.to raise_error(Faraday::TimeoutError)

      op.clear!
    end

    it "#POST tells the server to sleep for n seconds in order to reproduce timeouts" do
      op.prime("userAsleepAgain", { username: "Test" }.to_json, content_type: :json, sleep: 10)

      f = ::Faraday.new('http://localhost:7003/get/')
      f.options.timeout = 0

      expect { f.get("/userAsleepAgain") }.to raise_error(Faraday::TimeoutError)

      op.clear!
    end

  end

  context "#PUT" do
    it "persists a request when told so" do
      op.prime("persisted", { text: "" }.to_json, persisted: true, content_type: :json)

      expect( JSON.parse(::Faraday.get("http://localhost:7003/get/persisted").body) ).to eq({ "text" => "" })

      ::Faraday.put("http://localhost:7003/get/persisted", { id: 1 }.to_json)

      expect( JSON.parse(::Faraday.get("http://localhost:7003/get/persisted").body, symbolize_names: true) ).to eq({ text: "", id: 1})
    end

  end

  context "Requests not primed" do

    it "GET", "tracks requests that have not been primed" do
      ::Faraday.get("http://localhost:7003/get/get/i-am-not-primed")
      expect( ::Faraday.get("http://localhost:7003/not-primed").body ).to include('i-am-not-primed')
      expect( ::Faraday.get("http://localhost:7003/not-primed").body ).to include('GET')
    end

    it "POST", "tracks requests that have not been primed" do
      ::Faraday.post("http://localhost:7003/get/post/i-am-not-primed")
      expect( ::Faraday.get("http://localhost:7003/not-primed").body ).to include('i-am-not-primed')
      expect( ::Faraday.get("http://localhost:7003/not-primed").body ).to include('POST')
    end

    it "PUT", "tracks requests that have not been primed" do
      ::Faraday.put("http://localhost:7003/get/put/i-am-not-primed", "")
      expect( ::Faraday.get("http://localhost:7003/not-primed").body ).to include('i-am-not-primed')
      expect( ::Faraday.get("http://localhost:7003/not-primed").body ).to include('PUT')
    end

  end

  context "lets you know how many times a request is made for a path" do

    it "GET" do
      op.prime("continue", { username: "Test" }.to_json, content_type: :json)
      expect( ::Faraday.get("http://localhost:7003/requests/continue").body ).to include("\"count\":0")
      expect( op.count('continue') ).to eq(0)
      ::Faraday.get("http://localhost:7003/get/continue")
      expect( op.count('continue') ).to eq(1)
      expect( ::Faraday.get("http://localhost:7003/requests/continue").body ).to include("\"count\":1")
    end

    it "POST" do
      op.prime("kermit", { username: "Test" }.to_json, content_type: :json)
      expect( ::Faraday.get("http://localhost:7003/requests/kermit").body ).to include("\"count\":0")
      expect( op.count('kermit') ).to eq(0)
      ::Faraday.post("http://localhost:7003/get/kermit")
      expect( op.count('kermit') ).to eq(1)
      expect( ::Faraday.get("http://localhost:7003/requests/kermit").body ).to include("\"count\":1")
    end

  end

  context "it returns the requests made for a path" do

    it "GET" do
      op.prime("continue", { username: "Test" }.to_json, content_type: :json)
      ::Faraday.get("http://localhost:7003/get/continue")
      expect( ::Faraday.get("http://localhost:7003/requests/continue").body ).to include("\"requests\":[{\"method\":\"GET\",\"body\":{}}]")
      expect( op.requests("continue") ).to eq([{ "method" => "GET", "body" => {} }])
    end

    it "POST" do
      op.prime("kermit", { username: "Test" }.to_json, content_type: :json)
      ::Faraday.post("http://localhost:7003/get/kermit", { username: "Test" })
      expect( ::Faraday.get("http://localhost:7003/requests/kermit").body ).to include("\"requests\":[{\"method\":\"POST\",\"body\":{\"username\":\"Test\"}}]")
      expect( op.requests("kermit") ).to eq([{ "method" => "POST", "body" => { "username" => "Test" } }])
    end

    it "PUT" do
      op.prime("put/kermit", { username: "Test" }.to_json, content_type: :json)
      ::Faraday.put("http://localhost:7003/get/put/kermit", { username: "Test" })
      expect( op.requests("put/kermit") ).to eq([{ "method" => "PUT", "body" => { "username" => "Test" } }])
    end

    it "returns a decoded body" do
      op.prime("kermit", { username: "Test" }.to_json, content_type: :json)
      ::Faraday.post("http://localhost:7003/get/kermit", { word: "with spaces and other shit" })
      expect( op.requests("kermit") ).to eq([{ "method" => "POST", "body" => {"word" => "with spaces and other shit"} }])
    end


  end

end
