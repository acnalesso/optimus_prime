require "faraday"
require "sinatra/base"
require "json"

module OptimusPrime

  class Server < ::Sinatra::Base
    after do
       headers 'Access-Control-Allow-Origin' => '*',
               'Access-Control-Allow-Headers' => env['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'],
               'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST', 'PATCH']
    end

    set :public_folder, __dir__ + "/server/public"
    set :show_exceptions, false
    set :raise_erros, false

    @@responses ||= {}
    @@requests ||= {}
    @@not_primed ||= {}

    options "/*" do
    end

    patch "/get/*" do
      response = prime_store.get(path)

      if response.nil?
        @@not_primed[path] = { time: Time.now.to_s, HTTP_METHOD: env["REQUEST_METHOD"] }
        return 404
      end

      body = parse_request(response[:content_type])

      if response[:requested_with]
        return 404 unless body.include?(response[:requested_with])
      end

      sleep(response[:sleep].to_i) if response[:sleep]

      if response[:persisted]
        response[:body] = JSON.parse(response[:body]).merge!(body).to_json
        prime_store.set(path, response);
      end

      record_request(path, body)
      content_type(response[:content_type])
      status(response[:status_code] || 201)
      return "" if response[:status_code] =~ /500|404/
    end

    put "/get/*" do
      response = prime_store.get(path)

      if response.nil?
        @@not_primed[path] = { time: Time.now.to_s, HTTP_METHOD: env["REQUEST_METHOD"] }
        return 404
      end

      body = parse_request(response[:content_type])

      if response[:requested_with]
        return 404 unless body.include?(response[:requested_with])
      end

      sleep(response[:sleep].to_i) if response[:sleep]

      if response[:persisted]
        response[:body] = JSON.parse(response[:body]).merge!(body).to_json
        prime_store.set(path, response);
      end

      record_request(path, body)
      content_type(response[:content_type])
      status(response[:status_code] || 201)
      return "" if response[:status_code] =~ /500|404/
    end

    post "/get/*" do
      prime = prime_store.get(path)
      with_valid_prime(path, prime) do
        set_http_headers(prime)
        body_response(prime)
      end
    end

    def set_http_headers(prime)
      content_type(prime.content_type)
      status(prime.status_code)
    end

    def body_response(prime)
      sleep(prime.sleep.to_i) if prime.sleep
      [500, 404].include?(prime.status_code.to_i) ? "" : prime.body
    end

    def update_prime(prime, content_body)
      prime.body = JSON.parse(prime.body).merge!(content_body).to_json
      prime_store.set(path, prime)
    end

    def with_valid_prime(path, prime)
      unless prime
        not_primed_store.set(path, time: Time.now.to_s, HTTP_METHOD: env["REQUEST_METHOD"] )
        return 404
      end

      if prime.has_requested_with?
        request_body = request.body.read.tap { request.body.rewind }
        return 404 unless request_body.include?(prime.requested_with)
      end

      request_body = parse_request(prime.content_type)

      update_prime(prime, request_body) if prime.persisted?

      # @todo not sure what this is about
      record_request(path, request_body)

      yield request_body if block_given?
    end

    get "/get/*" do
      response = prime_store.get(path)
      require 'pry'
      binding.pry

      if response.nil?
        @@not_primed[path] = { time: Time.now.to_s, HTTP_METHOD: env["REQUEST_METHOD"] }
        return 404
      end

      record_request(path, {})

      sleep(response[:sleep].to_f) if response[:sleep]

      content_type(response[:content_type])
      status(response[:status_code])
      return "" if response[:status_code] =~ /500|404/
      response[:body]
    end

    post "/prime" do
      path = params["path_name"]
      require 'pry'
      binding.pry
      prime_store.set(path, Prime.new(params))
      requests[path] = { count: 0, last_request: nil }
      201
    end

    def prime_store
      @@prime_store ||= InMemoryStore.new
    end

    def not_primed_store
      @@not_primed_store ||= InMemoryStore.new
    end

    get "/show" do
      content_type :json
      responses.to_json
    end

    get "/clear" do
      @@responses = {}
    end

    get "/requests/*" do
      requests[path].to_json
    end

    get "/requests" do
      @@requests.to_json
    end

    get "/not-primed" do
      content_type :json
      @@not_primed.to_json
    end

    def record_request(path,  body)
      requests[path][:count] += 1
      request_made = { method: self.env["REQUEST_METHOD"], body: body, headers: { content_type: request.content_type, accept: request.accept } }
      @@requests[path][:last_request] = request_made
    end

    def path
      # self.env["REQUEST_URI"].scan(/^\/get\/([\/\w+]+)(\/|\?|$)/).flatten[0]
      @path ||= self.env["REQUEST_URI"].sub(/\/get\/|\/requests\//, "")
    end


    private

    def parse_request(content_type)
      if content_type.match(/json/)
        request_body = request.body.read
        request_body = request_body.empty? ? "{}" : request_body
        request_body = JSON.parse(request_body)
      else
        request_body = request.body.read
      end
      request.body.rewind
      request_body
    end

    def responses
      store
      # @@responses
    end

    def requests
      @@requests
    end

    def get_boolean(boolean)
      boolean == "true"
    end
  end
end
