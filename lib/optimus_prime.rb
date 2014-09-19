require "optimus_prime/version"
require "optimus_prime/server"

module OptimusPrime


  class Cannon

    $port = 7002

    def self.fire!(port)
      $port = port
      self.new.start_server
    end

    attr_reader :op_port

    def initialize
      @op_port = $port
    end

    def start_server

      return system("echo '\nOptimus is already priming :)\n\n'") if File.exist?("#{current_path}/tmp/pids/optimus_prime.pid")

      unless   File.directory?("#{current_path}/tmp/pids")
        system("echo 'Creating tmp/pid' && mkdir -p #{current_path}/tmp/pids")
      end

      unless File.exist?("#{current_path}/tmp/pids/optimus_prime.pid")
        if not `lsof -i:#{op_port}`.empty?
          return system("echo '\n\n------> Ooops looks like this port is already in use\n-------> Please kill it!!!\n'")
        end

        system("echo '\nStarting Optimus Prime\n'")
        puts system("thin start -c #{optimus_prime_path} -p #{op_port} -P #{current_path}/tmp/pids/optimus_prime.pid -l #{current_path}/optimus_prime.log -D -d")

        while :starting_server
          sleep(2) and break if File.exist?("#{current_path}/tmp/pids/optimus_prime.pid")
        end
      end
    end

    def optimus_prime_path
      File.expand_path('../', __dir__)
    end

    def current_path; `pwd`.chomp; end
  end


  class Base

    attr_reader :wait_for, :op_port

    def initialize(opts={})
      @wait_for = opts[:wait_for] || 3
      @op_port = $port
    end

    def prime(path_name, response="", options={})
      ::Faraday.post("http://localhost:#{op_port}/prime", { path_name: path_name, response: response }.merge!(options))
    end

    def clear!
      ::Faraday.get("http://localhost:#{op_port}/clear")
    end

    def count(path_name)
      requests = ::Faraday.get("http://localhost:#{op_port}/requests/#{path_name}").body
      JSON.parse(requests)["count"]
    end

    def last_request_for(path_name)
      seconds = 0
      while :waiting
        return {} if seconds > wait_for.to_f
        sleep(0.1)
        seconds += 0.1

        requests = ::Faraday.get("http://localhost:#{op_port}/requests/#{path_name}").body
        last_request = JSON.parse(requests)["last_request"]
        return last_request if !last_request.nil? && !last_request.empty?
      end
    end

    def wait_until_request(path_name, &block)
      seconds = 0
      while :waiting
        sleep(0.1)

        raise "Timeout - waited for: #{wait_for}. \n--> No requests have been made to: #{path_name} endpoint." if seconds > wait_for.to_f
        seconds += 0.1

        request = ::Faraday.get("http://localhost:#{op_port}/requests/#{path_name}").body

        last_request = JSON.parse(request)["last_request"]

        begin
          return true if block.call(last_request)
          rescue Exception => e
            raise "#{e}" if seconds > wait_for.to_f
        end

      end
    end

  end
end
