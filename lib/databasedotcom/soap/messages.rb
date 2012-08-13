require 'htmlentities'
require 'Time'

module Databasedotcom
  module Soap
  	class Messages

      def self.build_message(method, body, session_id, additionals)
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
     <urn:;;;method;;;>
      ;;;external_id_field;;;
      ;;;body;;;
     </urn:;;;method;;;>
  </soapenv:Body>
</soapenv:Envelope>"
        Messages::apply_template message, {:method => method.to_s, :body => body, :session_id => session_id, :external_id_field => additionals[:external_id_field]}
      end

      # Serializes the SObject as XML atom required by the Force.com SOAP API
      def self.convert_to_soap_message(sobject, soap_action = :create, additionals = {:fields_to_null => nil, :external_id_field => nil})       
        return nil unless sobject.is_a?(Databasedotcom::Sobject::Sobject)
        return "<urn:ids>#{sobject.Id}</urn:ids>" if soap_action == :delete

        coder = HTMLEntities.new
        field_list = sobject.instance_variables
          .select {|f| 
            field_name = sobject.instance_variable_get(f) 
            valid = true
            valid &= !sobject.instance_variable_get(f).to_s.empty?
            valid &= (soap_action == :create && sobject.class.createable?(f.to_s[1..-1])) || (soap_action == :update && sobject.class.updateable?(f.to_s[1..-1])) || soap_action == :upsert
            valid
          }
          .map    {|f| [f.to_s[1..-1], self.convert(sobject, f, coder) ] }
        fields = Hash[*field_list.flatten]
        additional = Messages::send("#{soap_action.to_s}_message", sobject, additionals) if Messages::respond_to?("#{soap_action.to_s}_message")
        
        soap =  "<urn:sObjects xsi:type=\"urn1:#{sobject.class.to_s.split('::').last}\">"
        soap << additional if additional
        soap << fields.map {|k,v| "<#{k}>#{v}</#{k}>" if v }.join("\n")
        soap << "</urn:sObjects>"
        soap
      end

  		private

      def self.convert(sobject, field_name, coder)
        value = case sobject.class.field_type(field_name.to_s[1..-1])
        when "date"
          return self.convert_to_date_string sobject.instance_variable_get(field_name)
        else
          sobject.instance_variable_get(field_name)
        end
        
        value = coder.encode(value) if value.class.to_s == String.to_s
        value
      end

      def self.convert_to_date_string(date)
        case date.class.to_s
        when Time.to_s
          date.iso8601
        when String.to_s
          Time.parse(date).iso8601
        else
          nil
        end
      rescue
        nil
      end

      def self.update_message(sobject, additionals)
        message = "<urn1:Id>#{sobject.Id}</urn1:Id>"
        message << additionals[:fields_to_null].map{|field_name| "<urn1:fieldsToNull>#{field_name}</urn1:fieldsToNull>" }.join if additionals[:fields_to_null]
        message
      end

  		def self.apply_template(template_string, value_hash = {})
  			template_string.gsub( /;;;(.*?);;;/ ) { (value_hash[$1] || value_hash[$1.to_sym]).to_s }
  		end
  	end
  end
end
 
