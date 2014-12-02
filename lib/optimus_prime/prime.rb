class Response

  attr_reader :body, :status_code, :content_type

  def initialize(request)
    @body = request[:body]
    @status_code = request[:status_code]
    @content_type = request[:content_type]
  end

  def requested_with?
    !!@request[:requested_with]
  end

end

class Prime
  ATTRIBUTES = [
    :body, :status_code, :content_type, :requested_with, :sleep, :persisted
  ]
  attr_reader *ATTRIBUTES

  def initialize(params)
    return unless params
    @params = params
    @content_type = params[:content_type] || :html
    @body = params[:body]
    @status_code = params[:status_code] || 200
    @requested_with = params[:requested_with] || false
    @sleep = params[:sleep] || false
    @persisted = params[:persisted] || false
  end

  def [](key)
    self.send(key)
  end

  def has_requested_with?
    !!requested_with
  end

  def persisted?
    !!persisted
  end

  def to_hash
    ATTRIBUTES.each_with_object({}) do |attr, hash|
      hash[attr] = self.send(attr)
    end
  end
end
