require "faraday"
require "sinatra/base"
require "json"

module OptimusPrime

  class Server < ::Sinatra::Base

    set :public_folder, __dir__ + "/server/public"

    post "/get/*" do
      path = self.env["REQUEST_URI"].sub("/get/", "")
      response = responses[path]
      return 404 if response.nil?
      content_type(response[:content_type] || :html)
      status(response[:status_code])
      response[:body]
    end

    get "/get/*" do
      path = self.env["REQUEST_URI"].sub("/get/", "")
      response = responses[path]
      return 404 if response.nil?
      content_type(response[:content_type] || :html)
      status(response[:status_code])
      response[:body]
    end

    post "/prime" do
      path = params["path_name"]
      responses[path] = { content_type: params["content_type"], body: params["response"], status_code: (params["status_code"] || 200) }
      201
    end

    get "/show" do
      content_type :json
      responses.to_json
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
