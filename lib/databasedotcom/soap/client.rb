require 'net/https'
require "uri"

module Databasedotcom
  module Soap
  	class Client
  		@record_limit = 200

  		def insert(array_of_sobjects = [])
  			subject = Client::filter_sobjects(array_of_sobjects)
  			@rest_client = subject.first.client

  			Client::soap_messages(subject).each{|slice|
  				puts @rest_client.oauth_token
  				body = Databasedotcom::Soap::Messages::build_insert({:body => slice.join("\n"), :session_id => @rest_client.oauth_token})
  				self.http_request({:body => body, :soap_action => 'create'})
  			}
  		end	

  		def self.filter_sobjects(array_of_sobjects = [])
  			array_of_sobjects.select{|obj| obj.is_a?(Databasedotcom::Sobject::Sobject)}
  		end

  		# slices the sobjects in to chunks of +@record_limit+ pieces and converts them to a soap message
  		def self.soap_messages(array_of_sobjects = [])
  			Client::filter_sobjects(array_of_sobjects)
  				.map{|sobject| sobject.to_soap_message}
  				.each_slice(@record_limit)
  		end

  		def http_request(hash = {})
  		  	uri = URI.parse("#{@rest_client.instance_url}/services/Soap/c/#{@rest_client.version}")
  		  	http = create_http_socket uri

        	request = create_http_request(hash[:body], uri)

        	response = http.request request
        	log_response response
        	response
  		end

  		def log_response(response)
  			puts "***** SOAP RESPONSE STATUS:\n#{response.code}\n***** BODY:\n#{response.body}" if @rest_client.debugging
  		end

  		def create_http_socket(uri)
  			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = true
        	http.ca_file = @rest_client.ca_file if @rest_client.ca_file
        	http.verify_mode = @rest_client.verify_mode if @rest_client.verify_mode	
       		http	
  		end
  		
  		def create_http_request(body, uri)
			request = Net::HTTP::Post.new(uri.request_uri)
			request.initialize_http_header({
				"User-Agent" 	=> "databasedotcom soap extensions",
				"Content-Type" 	=> "text/xml; charset=utf-8",
				"Content-Length"=> body.length.to_s,
				"SOAPAction" 	=> "create",
				"Host" 			=> uri.host,
				"Expect"		=> "100-continue"
			})
			request.body = body
			log_http_request request
			request
  		end

  		def log_http_request(http_request)
  			puts "***** SOAP REQUEST BODY:\n#{request.body}" if @rest_client.debugging
  		end
  	end
  end
end