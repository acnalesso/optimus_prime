require "optimus_prime/version"
require "optimus_prime/server"

module OptimusPrime

  class Base

    def prime(path_name, response="", options={})
      ::Faraday.post("http://localhost:7002/prime", { path_name: path_name, response: response }.merge!(options))
    end

    def get(path_name)
      ::Faraday.get("http://localhost:7002/get", { path_name: path_name }).tap { |r| yield(r) if ::Kernel.block_given? }.body
    end

    def status_code; 200; end

    def body; "I am a parameter"; end
  end
end
