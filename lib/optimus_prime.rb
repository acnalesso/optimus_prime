require "optimus_prime/version"
require "optimus_prime/server"

module OptimusPrime

  def self.restart_server
    self.stop_server
    self.start_server
  end

  def self.start_server
    if `ls ./tmp/pids`.include?("optimus_prime.pid")
      return `echo 'Optimus is already priming :)'`
    else
      `thin start -p 7002 -P ./tmp/pids/optimus_prime.pid -d`
      while true
        break if `ls ./tmp/pids`.include?("optimus_prime.pid")
      end
    end
  end

  def self.stop_server
    cmd = `thin stop -P ./tmp/pids/optimus_prime.pid`
    while true
      break unless `ls ./tmp/pids`.include?("optimus_prime.pid")
    end
    cmd
  end

  class Base

    def prime(path_name, response="", options={})
      ::Faraday.post("http://localhost:7002/prime", { path_name: path_name, response: response }.merge!(options))
    end

    def get(path_name)
      ::Faraday.get("http://localhost:7002/get", { path_name: path_name }).tap { |r| yield(r) if ::Kernel.block_given? }.body
    end

  end
end
