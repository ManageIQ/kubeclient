# Kubernetes HTTP Exceptions
class KubeException < StandardError
  attr_reader :error_code, :message, :response

  def initialize(error_code, message, response)
    @error_code = error_code
    @message = message
    @response = response
  end

  def to_s
    string = "HTTP status code #{@error_code}, #{@message}"
    if @response.is_a?(RestClient::Response) && @response.request
      string << " for #{@response.request.method.upcase} #{@response.request.url}"
    end
    string
  end
end
