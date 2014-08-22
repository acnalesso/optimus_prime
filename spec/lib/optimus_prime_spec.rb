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

  it "retrieves from url with params" do
    op.prime("getUser?id=10&queue=NaN", { username: "Test" }.to_json, content_type: :json)
    response = ::Faraday.get('http://localhost:7003/get/getUser?id=10&queue=NaN')

    expect( JSON.parse(response.body) ).to eq({ "username" => "Test" })
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

  it "#POST creates a record for with default params" do
    op.prime("posts/1", {}, content_type: :json)

    ::Faraday.post("http://localhost:7003/get/posts/1", { text: "I have been created", age: 21, category: "user" })

    expect( JSON.parse(::Faraday.get("http://localhost:7003/get/posts/1").body, symbolize_names: true) ).to eq({:age=>"21", :category=>"user", :text=>"I have been created"})
  end

  context "#PUT" do
    it "persists a request when told so" do
      op.prime("persisted", { text: "" }.to_json, persisted: true, content_type: :json)

      expect( JSON.parse(::Faraday.get("http://localhost:7003/get/persisted").body) ).to eq({ "text" => "" })

      ::Faraday.put("http://localhost:7003/get/persisted", { id: 1 })

      expect( JSON.parse(::Faraday.get("http://localhost:7003/get/persisted").body, symbolize_names: true) ).to eq({ text: "", id: "1"})
    end

  end

end
