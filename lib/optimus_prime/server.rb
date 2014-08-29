require "faraday"
require "sinatra/base"
require "json"

module OptimusPrime

  class Server < ::Sinatra::Base

    set :public_folder, __dir__ + "/server/public"

    put "/get/*" do
      path = get_path
      response = responses[path]

      return 404 if response.nil?

      if response[:requested_with]
        return 404 unless eval("request.body.string.include?('#{response[:requested_with]}')")
      end

      sleep(response[:sleep].to_i) if response[:sleep]

      if response[:persisted]
        new_body = params.tap { |p| p.delete("splat"); p.delete("captures") }

        @@responses[path][:body] = JSON.parse(response[:body]).merge!(new_body).to_json
      end
      201
    end

    post "/get/*" do
      path = get_path
      response = responses[path]
      return 404 if response.nil?

      if response[:requested_with]
        return 404 unless eval("request.body.string.include?('#{response[:requested_with]}')")
      end


      if response[:persisted]
        new_body = params.tap { |p| p.delete("splat"); p.delete("captures") }
        @@responses[path][:body] = new_body.to_json
      end

      content_type(response[:content_type])
      status(response[:status_code])

      sleep(response[:sleep].to_i) if response[:sleep]

      response[:body]
    end

    def get_path
      # self.env["REQUEST_URI"].scan(/^\/get\/([\/\w+]+)(\/|\?|$)/).flatten[0]
      self.env["REQUEST_URI"].sub("/get/", "")
    end

    get "/get/*" do
      path = get_path
      response = responses[path]
      return 404 if response.nil?
      sleep(response[:sleep].to_f) if response[:sleep]

      content_type(response[:content_type])
      status(response[:status_code])
      response[:body]
    end

    post "/prime" do
      path = params["path_name"]
      responses[path] = { content_type: (params["content_type"] || :html), body: params["response"], status_code: (params["status_code"] || 200), requested_with: (params["requested_with"] || false), sleep: (params["sleep"] || false), persisted: (params["persisted"] || false) }
      201
    end

    get "/show" do
      content_type :json
      responses.to_json
    end

    get "/clear" do
      @@responses = {}
    end

    private

      def responses
        @@responses ||= {}
      end

      def get_boolean(boolean)
        boolean == "true"
      end

  end

end
