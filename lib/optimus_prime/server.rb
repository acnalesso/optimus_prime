require "faraday"
require "sinatra/base"
require "json"

module OptimusPrime

  class Server < ::Sinatra::Base
    before do
       content_type :json
       headers 'Access-Control-Allow-Origin' => '*',
                'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST']
    end

    set :public_folder, __dir__ + "/server/public"

    @@responses ||= {}
    @@requests ||= {}
    @@not_primed ||= {}

    patch "/get/*" do
      path = get_path
      response = responses[path]

      if response.nil?
        @@not_primed[path] = { time: Time.now.to_s, HTTP_METHOD: env["REQUEST_METHOD"] }
        return 404
      end

      if response[:requested_with]
        request.body.rewind
        return 404 unless eval("request.body.read.include?('#{response[:requested_with]}')")
      end

      sleep(response[:sleep].to_i) if response[:sleep]

      if response[:persisted]
        new_body = request.body.read
        @@responses[path][:body] = JSON.parse(response[:body]).merge!(JSON.parse(new_body)).to_json
      end

      record_request(path)
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

      if response[:requested_with]
        request.body.rewind
        return 404 unless eval("request.body.read.include?('#{response[:requested_with]}')")
      end

      sleep(response[:sleep].to_i) if response[:sleep]

      if response[:persisted]
        new_body = request.body.read
        @@responses[path][:body] = JSON.parse(response[:body]).merge!(JSON.parse(new_body)).to_json
      end

      record_request(path)
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

      if response[:requested_with]
        request.body.rewind
        return 404 unless eval("request.body.read.include?('#{response[:requested_with]}')")
      end


      if response[:persisted]
        new_body = params.tap { |p| p.delete("splat"); p.delete("captures") }
        @@responses[path][:body] = new_body.to_json
      end

      record_request(path)

      content_type(response[:content_type])
      status(response[:status_code])

      sleep(response[:sleep].to_i) if response[:sleep]

      response[:body]
    end

    def record_request(path)
      requests[path][:count] += 1
      params.delete("splat")
      params.delete("captures")
      request_made = { method: self.env["REQUEST_METHOD"], body: params, headers: { content_type: request.content_type, accept: request.accept } }
      requests[path][:last_request] = request_made
    end

    def get_path
      # self.env["REQUEST_URI"].scan(/^\/get\/([\/\w+]+)(\/|\?|$)/).flatten[0]
      self.env["REQUEST_URI"].sub(/\/get\/|\/requests\//, "")
    end

    get "/get/*" do
      path = get_path
      response = responses[path]

      if response.nil?
        @@not_primed[path] = { time: Time.now.to_s, HTTP_METHOD: env["REQUEST_METHOD"] }
        return 404
      end

      record_request(path)

      sleep(response[:sleep].to_f) if response[:sleep]

      content_type(response[:content_type])
      status(response[:status_code])
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

    private

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
