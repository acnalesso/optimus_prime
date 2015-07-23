$LOAD_PATH.unshift __dir__
require "lib/optimus_prime"

puts "Running config.ru now"
run OptimusPrime::Server
