module Databasedotcom
  module Soap
  	class Messages
  		def self.build_insert(value_hash = {})
        value_hash[:method] = "create"
  		  Messages::build_message value_hash
  		end

  		def self.build_delete(value_hash = {})
  			value_hash[:method] = "delete"
        Messages::build_message value_hash
  		end

  		def self.build_update(value_hash = {})
			  value_hash[:method] = "update"
        Messages::build_message value_hash
  		end

  		def self.build_upsert(value_hash = {})
        value_hash[:method] = "upsert"
        value_hash[:external_id_field] = "<urn:externalIDFieldName>#{value_hash[:external_id_field]}</urn:externalIDFieldName>"
        Messages::build_message value_hash
  		end

      # Serializes the SObject as XML atom required by the Force.com SOAP API
      def self.convert_to_soap_message(s_object, soap_action = :create, &block)       
        return nil unless s_object.is_a?(Databasedotcom::Sobject::Sobject)
        return "<urn:ids>#{s_object.Id}</urn:ids>" if soap_action == :delete

        field_list = s_object.instance_variables
          .select {|f| 
            field_name = s_object.instance_variable_get(f) 
            (soap_action == :create && s_object.createable?(f.to_s[1..-1])) || (soap_action == :update && s_object.updateable?(f.to_s[1..-1])) || soap_action == :upsert
          }
          .map    {|f| [f.to_s[1..-1], s_object.instance_variable_get(f)] }
        fields = Hash[*field_list.flatten]

        soap =  "<urn:sObjects xsi:type=\"urn1:#{s_object.class.to_s.split('::').last}\">"
        soap << yield(s_object) if block
        soap << fields.map {|k,v| "<#{k}>#{v}</#{k}>" }.join("\n")
        soap << "</urn:sObjects>"
        soap
      end

  		private

  		def self.apply_template(template_string, value_hash = {})
  			template_string.gsub( /;;;(.*?);;;/ ) { (value_hash[$1] || value_hash[$1.to_sym]).to_s }
  		end

      def self.build_message(value_hash = {})
        message = "<?xml version=\"1.0\" encoding=\"utf-8\"?>   
<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
  xmlns:urn=\"urn:enterprise.soap.sforce.com\"
  xmlns:urn1=\"urn:sobject.enterprise.soap.sforce.com\"
  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
  <soapenv:Header>
     <urn:SessionHeader>
        <urn:sessionId>;;;session_id;;;</urn:sessionId>
     </urn:SessionHeader>
  </soapenv:Header>
  <soapenv:Body>
      ;;;external_id_field;;;
     <urn:;;;method;;;>
      ;;;body;;;
     </urn:;;;method;;;>
  </soapenv:Body>
</soapenv:Envelope>"
        Messages::apply_template message, value_hash
      end
  	end
  end
end