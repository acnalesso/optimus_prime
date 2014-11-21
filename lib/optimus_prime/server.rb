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
      path = get_path
      response = responses[path]

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
        @@responses[path][:body] = JSON.parse(response[:body]).merge!(body)
      end

      record_request(path, body)
      content_type(response[:content_type])
      status(response[:status_code] || 201)
      return "" if response[:status_code] =~ /500|404/
    end

    put "/get/*" do
      path = get_path
      response = responses[path]

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
        @@responses[path][:body] = JSON.parse(response[:body]).merge!(body).to_json
      end

      record_request(path, body)
      content_type(response[:content_type])
      status(response[:status_code] || 201)
      return "" if response[:status_code] =~ /500|404/
    end

    post "/get/*" do
      path = get_path
      response = responses[path]

      if response.nil?
        @@not_primed[path] = { time: Time.now.to_s, HTTP_METHOD: env["REQUEST_METHOD"] }
        return 404
      end

      body = parse_request(response[:content_type])

      if response[:requested_with]
        return 404 unless body.include?(response[:requested_with])
      end

      if response[:persisted]
        @@responses[path][:body] = body
      end

      record_request(path, body)
      content_type(response[:content_type])
      status(response[:status_code])
      sleep(response[:sleep].to_i) if response[:sleep]
      return "" if response[:status_code] =~ /500|404/
      response[:body]
    end

    get "/get/*" do
      path = get_path
      response = responses[path]

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
      responses[path] = { content_type: (params["content_type"] || :html), body: params["response"], status_code: (params["status_code"] || 200), requested_with: (params["requested_with"] || false), sleep: (params["sleep"] || false), persisted: (params["persisted"] || false) }
      requests[path] = { count: 0, last_request: nil }
      201
    end

    get "/show" do
      content_type :json
      responses.to_json
    end

    get "/clear" do
      @@responses = {}
    end

    get "/requests/*" do
      path = get_path
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

    def get_path
      # self.env["REQUEST_URI"].scan(/^\/get\/([\/\w+]+)(\/|\?|$)/).flatten[0]
      self.env["REQUEST_URI"].sub(/\/get\/|\/requests\//, "")
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
      @@responses
    end

    def requests
      @@requests
    end

    def get_boolean(boolean)
      boolean == "true"
    end
  end
end
