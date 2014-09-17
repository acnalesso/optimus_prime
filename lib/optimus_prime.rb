require "optimus_prime/version"
require "optimus_prime/server"

module OptimusPrime

  @@op_port = 7002
  def self.op_port; @@op_port; end

  def self.restart_server
    self.stop_server
    self.start_server
  end

  def self.start_server(options={})
    @@op_port = 7003 if ENV["OP.ENV"] == "test"
    @@op_port = options[:port] if options[:port]

    `mkdir -p ./tmp/pids`
    return `echo 'Optimus is already priming :)'` if system("ls ./tmp/pids/optimus_prime.pid")
    path = `pwd`.chomp
    if system("cd #{optimus_prime_path} && echo '\nStarting Optimus Prime\n' && thin start -p #{op_port} -P #{path}/tmp/pids/optimus_prime.pid -l #{path}/optimus_prime.log -d -D")
      while :starting_server
        sleep(2) and break if `ls ./tmp/pids`.include?("optimus_prime.pid")
      end
    end
  end

  def self.optimus_prime_path
    File.expand_path('../', __dir__)
  end

  def self.current_path; `pwd`.chomp; end

  def self.stop_server
    path = `pwd`.chomp
    system("cd #{optimus_prime_path} && echo '\nStoping Optimus Prime\n' && thin stop -P #{path}/tmp/pids/optimus_prime.pid")
  end

  def self.full_path
    File.expand_path(__dir__)
  end

  class Base

    attr_reader :wait_for

    def initialize(opts={})
      @wait_for = opts[:wait_for] || 3
    end

    def prime(path_name, response="", options={})
      ::Faraday.post("http://localhost:#{OptimusPrime.op_port}/prime", { path_name: path_name, response: response }.merge!(options))
    end

    def clear!
      ::Faraday.get("http://localhost:#{OptimusPrime.op_port}/clear")
    end

    def count(path_name)
      requests = ::Faraday.get("http://localhost:#{OptimusPrime.op_port}/requests/#{path_name}").body
      JSON.parse(requests)["count"]
    end

    def last_request_for(path_name)
      seconds = 0
      while :waiting
        seconds += 0.3
        requests = ::Faraday.get("http://localhost:#{OptimusPrime.op_port}/requests/#{path_name}").body
        last_request = JSON.parse(requests)["last_request"]
        return last_request if !last_request.nil? && !last_request.empty?
        return {} if seconds.to_i == wait_for
        sleep(0.3)
      end
    end

  end
end
