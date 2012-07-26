require 'net/https'
require "uri"
require 'active_support/core_ext'

module Databasedotcom
  module Soap
  	class Client
  		@record_limit = 200 
  		@current_record = 0
  		@errors = nil

  		def insert(array_of_sobjects = [])
  			@current_record = 0
  			@errors = []

  			subject = Client::filter_sobjects(array_of_sobjects)
  			@rest_client = subject.first.client
  			action = "create"

  			Client::soap_messages(subject).each{|slice|
  				body = Databasedotcom::Soap::Messages::build_insert({:body => slice.join("\n"), :session_id => @rest_client.oauth_token})
  				response = self.http_request({:body => body, :soap_action => action})
  				read_response(response, array_of_sobjects, action){|sobject, result| sobject.Id = result["id"] }
  			}
  			@errors
  		end	

  		def delete(array_of_sobjects = [])
  			@current_record = 0
  			@errors = []

  			subject = Client::filter_sobjects(array_of_sobjects)
  			@rest_client = subject.first.client
  			action = "delete"

  			Client::soap_messages_for_delete(subject).each{|slice|
  				body = Databasedotcom::Soap::Messages::build_delete({:body => slice.join("\n"), :session_id => @rest_client.oauth_token})
  				response = self.http_request({:body => body, :soap_action => action})
  				puts response.body
  				read_response(response, array_of_sobjects, action){|sobject, result| sobject.Id = nil }
  			}
  			@errors
  		end

  		def update(array_of_sobjects = [], fields_to_null = [])
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

  		def read_response response, array_of_sobjects, action
  			hashed_response = Hash.from_xml(response.body)
  			
  			results = hashed_response["Envelope"]["Body"]["#{action}Response"]["result"]
  			results = [results] unless results.is_a?(Array)

  			results.each {|result|
  				if result["success"] == "true"
  					yield array_of_sobjects[@current_record], result
  				else
  					@errors.push Databasedotcom::Soap::SoapError.new(result, array_of_sobjects[@current_record])
  				end
  				@current_record += 1
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
  		  	uri = URI.parse("#{@rest_client.instance_url}/services/Soap/c/#{@rest_client.version}")
  		  	http = create_http_socket uri
  		  	hash[:uri] = uri

        	request = create_http_request(hash)

        	response = http.request request
        	log_http_response response
        	response
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
				"SOAPAction" 	=> "create",
				"Host" 			=> hash[:uri].host,
				"Expect"		=> "100-continue"
			})
			request.body = hash[:body]
			puts request.body
			log_http_request request
			request
  		end

  		def log_http_request(http_request)
  			puts "***** SOAP REQUEST BODY:\n#{http_request.body}" if @rest_client.debugging
  		end
  	end
  end
end