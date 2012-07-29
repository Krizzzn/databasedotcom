require 'net/https'
require "uri"
require 'active_support/core_ext'

module Databasedotcom
  module Soap
  	class Client
  		attr_accessor :rest_client, :record_limit
		
      @current_record = 0
  		@errors = nil

      def initialize()
        @record_limit = 200
      end

      def insert(*array_of_sobjects)
        perform_soap_action :create, array_of_sobjects
      end 

  		def delete(*array_of_sobjects)
        perform_soap_action(:delete, array_of_sobjects)
  		end

  		def update(array_of_sobjects = [], fields_to_null = nil)
        return perform_soap_action(:update, array_of_sobjects)

        throw StandardError("not implemented")

  			@current_record = 0
  			@errors = []

  			subject = Client::filter_sobjects(array_of_sobjects)

  			@rest_client = subject.first.client
  			action = "update"
  			Client::soap_messages_for_update(subject, fields_to_null).each{|slice|
  				body = Databasedotcom::Soap::Messages::build_update({:body => slice.join("\n"), :session_id => @rest_client.oauth_token})
  				response = self.http_request({:body => body, :soap_action => action})
  				read_response(response, array_of_sobjects, action){|sobject, result| sobject.Id = nil }
  			}
  			@errors
  		end

  		def upsert(array_of_sobjects = [], external_id_field)
        throw StandardError("not implemented")

  			@current_record = 0
  			@errors = []

  			subject = Client::filter_sobjects(array_of_sobjects)

  			@rest_client = subject.first.client
  			action = "upsert"
  			Client::soap_messages(subject).each{|slice|
  				body = Databasedotcom::Soap::Messages::build_upsert({:body => slice.join("\n"), :session_id => @rest_client.oauth_token, :external_id_field => external_id_field})
  				response = self.http_request({:body => body, :soap_action => action})
  				p response.body
  				read_response(response, array_of_sobjects, action){|sobject, result| sobject.Id = nil }
  			}
  			@errors
  		end

  		def self.soap_messages_for_delete(array_of_sobjects = [])
  			Client::filter_sobjects(array_of_sobjects)
  				.select {|sobject| sobject.Id}
  				.map 	{|sobject| "<urn:ids>#{sobject.Id}</urn:ids>"}
  				.each_slice(@record_limit)
  		end

  		def self.soap_messages_for_update(array_of_sobjects = [], fields_to_null)
  			fields_to_null_string = fields_to_null.map{|n| "<urn1:fieldsToNull>#{n.to_s}</urn1:fieldsToNull>"}.join
  			fields_to_null_string ||= ""

  			Client::filter_sobjects(array_of_sobjects)
  			  	.select {|sobject| sobject.Id}
  				.map{|sobject| sobject.to_soap_message{ fields_to_null_string } }
  				.each_slice(@record_limit)
  		end


  		def http_request(hash = {})
        raise ArgumentError.new(":body is not supplied") if !hash[:body] || hash[:body].empty?
        raise ArgumentError.new("@rest_client can not be null") if !@rest_client

  		  uri = URI.parse("#{@rest_client.instance_url}/services/Soap/c/#{@rest_client.version}")
  		  http = create_http_socket uri
  		  hash[:uri] = uri

       	request = create_http_request(hash)

       	response = http.request request
       	log_http_response response
       	response
  		end

      private

      def perform_soap_action(soap_action, array_of_sobjects)
        array_of_sobjects = [array_of_sobjects] unless array_of_sobjects.is_a?(Array)
        array_of_sobjects.flatten!
        @current_record = 0
        @errors = []
        valid_sobjects = Client::filter_sobjects(array_of_sobjects)

        return @errors if valid_sobjects.empty?
        @rest_client = valid_sobjects.first.client
        raise ArgumentError.new("#{valid_sobjects.first.client} does not have a rest client set") unless @rest_client 
        
        soap_messages(valid_sobjects, soap_action).each{|slice|
          body = Databasedotcom::Soap::Messages::send "build_#{soap_action.to_s}", {:body => slice.join("\n"), :session_id => @rest_client.oauth_token}
          response = self.http_request(:body => body, :action => soap_action.to_s)
          read_response(response, valid_sobjects, soap_action)
        }
        @errors
      end 

      # slices the sobjects in to chunks of +@record_limit+ pieces and converts them to a soap message
      def soap_messages(array_of_sobjects = [], soap_action)
        array_of_sobjects
          .map{|sobject| Databasedotcom::Soap::Messages::convert_to_soap_message(sobject, soap_action) }
          .each_slice(@record_limit)
      end

      def read_response response, array_of_sobjects, soap_action
        hashed_response = Hash.from_xml(response.body)
        
        results = hashed_response["Envelope"]["Body"]["#{soap_action.to_s}Response"]["result"]
        results = [results] unless results.is_a?(Array)

        results.each {|result|
          if result["success"] == "true"
            array_of_sobjects[@current_record].Id = case soap_action
                                                    when :create, :upsert, :update
                                                        result["id"]
                                                    when :delete
                                                       nil
                                                    end
          else
            @errors.push Databasedotcom::Soap::SoapError.new(result, array_of_sobjects[@current_record])
          end
          @current_record += 1
        }
      end

      def self.filter_sobjects(array_of_sobjects = [])
        array_of_sobjects.select{|obj| obj.is_a?(Databasedotcom::Sobject::Sobject)}
      end

  		def log_http_response(response)
  			puts "***** SOAP RESPONSE STATUS:\n#{response.code}\n***** BODY:\n#{response.body}" if @rest_client.debugging
  		end

  		def create_http_socket(uri)
  			http = Net::HTTP.new(uri.host, uri.port)
			  http.use_ssl = true
        http.ca_file = @rest_client.ca_file if @rest_client.ca_file
        http.verify_mode = @rest_client.verify_mode if @rest_client.verify_mode 
       	http	
  		end
  		
  		def create_http_request(hash = {})
			
			request = Net::HTTP::Post.new(hash[:uri].request_uri)
			request.initialize_http_header({
				"User-Agent" 	=> "databasedotcom soap extensions",
				"Content-Type" 	=> "text/xml; charset=utf-8",
				"Content-Length"=> hash[:body].length.to_s,
				"SOAPAction" 	=> hash[:action] || "",
				"Host" 			=> hash[:uri].host,
				"Expect"		=> "100-continue"
			})
			request.body = hash[:body]
			log_http_request request
			request
  		end

  		def log_http_request(http_request)
  			puts "***** SOAP REQUEST BODY:\n#{http_request.body}" if @rest_client.debugging
  		end
  	end
  end
end