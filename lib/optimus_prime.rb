require "optimus_prime/version"
require "optimus_prime/server"

module OptimusPrime

  def self.restart_server
    self.stop_server
    self.start_server
  end

  def self.start_server
    return `echo 'Optimus is already priming :)'` if `ls ./tmp/pids`.include?("optimus_prime.pid")
    `thin start -p 7002 -P ./tmp/pids/optimus_prime.pid -d`
    while :starting_server
      sleep(2) and break if `ls ./tmp/pids`.include?("optimus_prime.pid")
    end
  end

  def self.stop_server
    `thin stop -P ./tmp/pids/optimus_prime.pid`
    while :stopping_server
      break unless `ls ./tmp/pids`.include?("optimus_prime.pid")
    end
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
