OptimusPrime.restart_server

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

  context "it returns the last request made for a path" do

    it "GET" do
      op.prime("continue", { username: "Test" }.to_json, content_type: :json)
      ::Faraday.get("http://localhost:7003/get/continue", nil, { "Content-Type" => "application/json", "Accept" => "application/json" })
      expect( op.last_request_for("continue") ).to eq({ "method" => "GET", "body" => {}, "headers" => { "content_type" => "application/json", "accept" => ["application/json"] } })
    end

    it "POST" do
      op.prime("kermit", { username: "Test" }.to_json, content_type: :json)
      ::Faraday.post("http://localhost:7003/get/kermit", { username: "Test" })
      expect( op.last_request_for("kermit") ).to eq({ "method" => "POST", "body" => { "username" => "Test" }, "headers"=>{ "content_type"=>"application/x-www-form-urlencoded", "accept"=>["*/*"]} })
    end

    it "PUT" do
      op.prime("put/kermit", { username: "Test" }.to_json, content_type: :json)
      ::Faraday.put("http://localhost:7003/get/put/kermit", { username: "Test" })
      expect( op.last_request_for("put/kermit") ).to eq({"method"=>"PUT", "body"=>{"username"=>"Test"}, "headers"=>{"content_type"=>"application/x-www-form-urlencoded", "accept"=>["*/*"]}})
    end

    it "returns a decoded body" do
      op.prime("kermit", { username: "Test" }.to_json, content_type: :json)
      ::Faraday.post("http://localhost:7003/get/kermit", { word: "with spaces and other shit" })
      expect( op.last_request_for("kermit") ).to eq({"method"=>"POST", "body"=>{"word"=>"with spaces and other shit"}, "headers"=>{"content_type"=>"application/x-www-form-urlencoded", "accept"=>["*/*"]}})
    end

    it "tries for up to 0.1 seconds to get the last request" do
      op = OptimusPrime::Base.new(wait_for: 0.1)
      op.prime("waitMan", { status: "waiting" }.to_json, content_type: :json)
      Thread.new { sleep(0.01); ::Faraday.get("http://localhost:7003/get/waitMan", nil, { "Content-Type" => "application/json", "Accept" => "application/json" })}
      expect( op.last_request_for("waitMan") ).to eq({ "method" => "GET", "body" => {}, "headers" => { "content_type" => "application/json", "accept" => ["application/json"] } })
    end

    it "returns the last request as nil if it doesn't find a request after 0.1 seconds" do
      op = OptimusPrime::Base.new(wait_for: 0.1)
      op.prime("waitMan", { status: "waiting" }.to_json, content_type: :json)
      Thread.new { sleep(0.5); ::Faraday.get("http://localhost:7003/get/waitMan", nil, { "Content-Type" => "application/json", "Accept" => "application/json" })}
      expect( op.last_request_for("waitMan") ).to eq({})
    end

    it "sets default seconds for wait_for" do
      op = OptimusPrime::Base.new
      expect( op.wait_for ).to eq(3)
    end

  end

  context "allow devs to wait for a request to be made" do

    it "waits until the correct request has been made" do
      op = OptimusPrime::Base.new(wait_for: 1)
      op.prime("expectation", { status: "UNKOWN" }, content_type: :json)

      ::Faraday.post("http://localhost:7003/get/expectation", { status: "IN_PROGRESS" } )
      Thread.new { sleep(0.5); ::Faraday.post("http://localhost:7003/get/expectation", { status: "COMPLETED" } )}

      op.wait_until_request("expectation") do |request|
        expect(request["body"]["status"]).to eq("COMPLETED")
      end

    end

    it "does raise an error when it times out" do
      op = OptimusPrime::Base.new(wait_for: 0.1)
      op.prime("timeOut", { status: "NO" }, content_type: :json)

      Thread.new { sleep(1); ::Faraday.post("http://localhost:7003/get/timeOut", { status: "YES" } ) }

      expect do
        op.wait_until_request("timeOut") { |request| }
      end.to raise_error
    end

  end

end
