$LOAD_PATH.unshift __dir__
require "lib/optimus_prime"

puts "Running config.ru now"
use OptimusPrime::Wait
use OptimusPrime::NormaliseUniqueURL
run OptimusPrime::Server
