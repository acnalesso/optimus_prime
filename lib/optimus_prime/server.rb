require "faraday"
require "sinatra/base"
require "json"

module OptimusPrime

  class Server < ::Sinatra::Base
    after do
       headers 'Access-Control-Allow-Origin' => '*',
               'Access-Control-Allow-Headers' => String(env['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']),
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

      return response[:status_code] if response[:status_code].to_s =~ /500|404/

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
    end

    put "/get/*" do
      path = get_path
      response = responses[path]

      if response.nil?
        @@not_primed[path] = { time: Time.now.to_s, HTTP_METHOD: env["REQUEST_METHOD"] }
        return 404
      end

      return response[:status_code] if response[:status_code].to_s =~ /500|404/

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
    end

    post "/get/*" do
      path = get_path
      response = responses[path]

      if response.nil?
        @@not_primed[path] = { time: Time.now.to_s, HTTP_METHOD: env["REQUEST_METHOD"] }
        return 404
      end

      body = parse_request(response[:content_type])

      return response[:status_code] if response[:status_code].to_s =~ /500|404/

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
      response[:body]
    end

    get "/get/*" do
      path = get_path
      response = responses[path]

      if response.nil?
        @@not_primed[path] = { time: Time.now.to_s, HTTP_METHOD: env["REQUEST_METHOD"] }
        return 404
      end

      return response[:status_code] if response[:status_code].to_s =~ /500|404/

      record_request(path, {})

      sleep(response[:sleep].to_f) if response[:sleep]

      content_type(response[:content_type])
      status(response[:status_code])
      response[:body]
    end

    post "/prime" do
      payload = env['rack.input'].read.tap { env['rack.input'].rewind }
      params = JSON(payload.empty? ? '{}' : payload)

      path = params["path_name"]
      responses[path] = { content_type: (params["content_type"] || :html), body: params["response"], status_code: (params["status_code"] || 200), requested_with: (params["requested_with"] || false), sleep: (params["sleep"] || false), persisted: (params["persisted"] || false) }
      requests[path] = { count: 0, last_request: nil }
      201
    end

    get "/show" do
      content_type :json
      responses.to_json
    end

    get "/add" do
      erb :add
    end

    post "/add" do
      body = params[:body]
      path = params[:path]
      content_type = params[:content_type]
      responses[path] = { content_type: (content_type || :html), body: body, status_code: 200, requested_with: false, sleep: false, persisted: false }
      requests[path] = { count: 0, last_request: nil }
      <<-HTML
        <h1>Done!</h1>
        <br>
        <a href='/add'>Back</a>
        <br>
        <a href='/get/#{path}'>View primed response</a>
        <br>
        <a href='/show'>View all</a>
      HTML
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
      cookies = request.cookies
      cookies.merge!(CGI::Cookie::parse(env["HTTP_X_COOKIES"]))
      custom_params = env["HTTP_X_PARAMS"]

      request_made = { method: self.env["REQUEST_METHOD"], body: body, headers: { content_type: request.content_type, accept: request.accept, cookies: cookies, custom_params: custom_params } }
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
