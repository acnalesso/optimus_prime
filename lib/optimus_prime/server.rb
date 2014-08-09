require "faraday"
require "sinatra/base"
require "json"

module OptimusPrime

  class Server < ::Sinatra::Base

    set :public_folder, __dir__ + "/server/public"

    post "/get/*" do
      p params["splat"].first
      response = primed[params["splat"].first]
      content_type response[:content_type]
      response[:body]
    end

    get "/get/*" do
      path = self.env["REQUEST_URI"].sub("/get/", "")
      response = primed[path]
      content_type response[:content_type] || "text"
      status response[:status_code]
      response[:body]
    end

    post "/prime" do
      path = params["path_name"]
      primed[path] = { content_type: params["content_type"], body: params["response"], status_code: (params["status_code"] || 200) }
      200
    end

    get "/show" do
      content_type :json
      primed.to_json
    end

    private

      def primed
        @@primed ||= {}
      end

  end

end
