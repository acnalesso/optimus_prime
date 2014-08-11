require "optimus_prime/version"
require "optimus_prime/server"

module OptimusPrime

  def self.restart_server
    self.stop_server
    self.start_server
  end

  def self.start_server
    `mkdir -p ./tmp/pids`
    return `echo 'Optimus is already priming :)'` if system("ls ./tmp/pids/optimus_prime.pid")
    path = `pwd`.chomp
    if system("cd #{optimus_prime_path} && echo '\nStarting Optimus Prime\n' && thin start -p 7002 -P #{path}/tmp/pids/optimus_prime.pid -l #{path}/optimus_prime.log -d -D")
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

    def prime(path_name, response="", options={})
      ::Faraday.post("http://localhost:7002/prime", { path_name: path_name, response: response }.merge!(options))
    end

  end
end
