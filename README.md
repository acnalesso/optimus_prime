# OptimusPrime
####“It’s been an honor serving with you all.”


## Installation

Add this line to your application's Gemfile:
```ruby
gem 'optimus_prime'
```

And then execute:
```bash
$ bundle
```
Or install it yourself as:
```bash
$ gem install optimus_prime
```

OptimusPrime allows developers to persist fake date and tell their API to talk
to it and get the desired response.

## Default configuration
  * localhost:7002/get -> default endpoint
  * returns 200 status code for GET,POST
  * sets content-type to text

## HTTP allowed requests
 * GET
 * POST

# Usage
```ruby
OptimusPrime.start_server
op = OptimusPrime::Base.new
op.prime("path_name", response, options)
```

## Changing Content Type:
```ruby
op.prime("users", { users json... }, { content_type: :json })
response = Faraday.get("http://localhost:7002/get/users")
response.headers["content-type"] #=> "application/json"
```

## Changing HTTP response method:
```ruby
op.prime("users", " response... ", { status_code: 404 })
response = Faraday.get("http://localhost:7002/get/users")
response.status #=> 404
```

## POST requests:
```ruby
op.prime("users", " response... ", status_code: 201)
response = Faraday.post("http://localhost:7002/get/users", { some data })
response.body #=> " response... "
```

## TODO
  * Move server initialisation into rake task in order to prevent it from initialising
from its directory.
  * Support DELETE, HEAD, PUT http methods
  * Support REGEX as a path
  * Support html templates
## Contributing

1. Fork it ( https://github.com/[my-github-username]/optimus_prime/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
