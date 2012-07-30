module Databasedotcom
  # An exception that thrown by the soap API
  module Soap
    class SoapError < StandardError
      # the s_object the error occured at.
      attr_accessor :s_object
  
      def initialize(hash = [], erroring_sobject = nil)
        error = hash["errors"]
        message = "#{error["statusCode"]} "
        message << "Field #{error["fields"]}: " if error["fields"]
        message << "#{error["message"]}"
        @s_object = erroring_sobject
        super(message)
      end
    end
  end
end