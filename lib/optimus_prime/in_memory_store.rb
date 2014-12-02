class InMemoryStore
  def initialize(client: {})
    @client = client
  end

  # @param [String] key
  # @param [Request] request
  def set(key, request)
    @client[key] = encode(request)
  end

  # @param [String] key
  # @return [Prime]
  def get(key)
    decode(@client[key])
  end

  private

  def encode(request)
    request.to_hash
  end

  def decode(hash)
    Prime.new(hash)
  end

  def merge(key, request)
    original_request_hash = get(key)
    original_request_hash.merge!(request.serialize)
    set(key, Request.new(original_request))
  end
end
