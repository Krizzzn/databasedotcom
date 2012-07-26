module Databasedotcom
  # An exception that thrown by the soap API
  module Soap
    class SoapError < StandardError
      # the s_object the error occured at.
      @s_object = nil
  
      def initialize(hash = [], erroring_sobject)
        error = hash["errors"]
        message = "#{error["statusCode"]} Field #{error["fields"]}: #{error["message"]}"
        @s_object = erroring_sobject
        super(message)
      end
    end
  end
end