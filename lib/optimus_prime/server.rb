require "faraday"
require "sinatra/base"
require "json"

module OptimusPrime

  class Server < ::Sinatra::Base

    set :public_folder, __dir__ + "/server/public"

    get "/get" do
      response = primed[params["path_name"]]
      content_type response[:content_type] || "text"
      response[:body]
    end

    post "/prime" do
      path = params["path_name"]
      primed[path] = { content_type: params["content_type"], body: params["response"] }
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
