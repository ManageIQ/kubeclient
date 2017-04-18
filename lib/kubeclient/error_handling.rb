module Kubeclient
  module ErrorHandling
    def handle_exception
      yield
    rescue RestClient::Exception => e
      json_error_msg = begin
        JSON.parse(e.response || '') || {}
      rescue JSON::ParserError
        {}
      end
      err_message = json_error_msg['message'] || e.message
      raise KubeException.new(e.http_code, err_message, e.response)
    end
  end
end
