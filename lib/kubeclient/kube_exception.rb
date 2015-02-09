# Kubernetes HTTP Exceptions
class KubeException < Exception
  attr_reader :error_code, :message

  def initialize(error_code, message)
    @error_code = error_code
    @message = message
  end

  def to_s
    'HTTP status code ' + @error_code.to_s + ', ' + @message
  end
end
