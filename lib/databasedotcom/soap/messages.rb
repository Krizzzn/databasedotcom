module Databasedotcom
  module Soap
  	class Messages
  		def self.build_insert(value_hash = {})
  			message = "<?xml version=\"1.0\" encoding=\"utf-8\"?>   
<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
  xmlns:urn=\"urn:enterprise.soap.sforce.com\"
  xmlns:urn1=\"urn:sobject.enterprise.soap.sforce.com\"
  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
  <soapenv:Header>
     <urn:SessionHeader>
        <urn:sessionId>:::session_id:::</urn:sessionId>
     </urn:SessionHeader>
  </soapenv:Header>
  <soapenv:Body>
     <urn:create>
     	:::body:::
     </urn:create>
  </soapenv:Body>
</soapenv:Envelope>"
			Messages::apply_template message, value_hash
  		end

  		def self.build_delete(value_hash = {})
  			message = "<?xml version=\"1.0\" encoding=\"utf-8\"?>   
<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
  xmlns:urn=\"urn:enterprise.soap.sforce.com\">
  <soapenv:Header>
     <urn:SessionHeader>
        <urn:sessionId>:::session_id:::</urn:sessionId>
     </urn:SessionHeader>
  </soapenv:Header>
  <soapenv:Body>
     <urn:delete>
     	:::body:::
     </urn:delete>
  </soapenv:Body>
</soapenv:Envelope>"
			Messages::apply_template message, value_hash
  		end

  		def self.build_update(value_hash = {})
			message = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
  xmlns:urn=\"urn:enterprise.soap.sforce.com\"
  xmlns:urn1=\"urn:sobject.enterprise.soap.sforce.com\"
  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
  <soapenv:Header>
     <urn:SessionHeader>
        <urn:sessionId>:::session_id:::</urn:sessionId>
     </urn:SessionHeader>
  </soapenv:Header>
  <soapenv:Body>
     <urn:update>
     	:::body:::
     </urn:update>
  </soapenv:Body>
</soapenv:Envelope>"
			Messages::apply_template message, value_hash
  		end

  		def self.build_upsert(value_hash = {})
  			message = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
  xmlns:urn=\"urn:enterprise.soap.sforce.com\"
  xmlns:urn1=\"urn:sobject.enterprise.soap.sforce.com\"
  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
  <soapenv:Header>
     <urn:SessionHeader>
        <urn:sessionId>:::session_id:::</urn:sessionId>
     </urn:SessionHeader>
  </soapenv:Header>
  <soapenv:Body>
     <urn:upsert>
        <urn:externalIDFieldName>:::external_id_field:::</urn:externalIDFieldName>
        :::body:::
     </urn:upsert>
  </soapenv:Body>
</soapenv:Envelope>"
			Messages::apply_template message, value_hash
  		end

  		private

  		def self.apply_template(template_string, value_hash = {})
  			template_string.gsub( /:::(.*?):::/ ) { (value_hash[$1] || value_hash[$1.to_sym]).to_s }
  		end
  	end
  end
end