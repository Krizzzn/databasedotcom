require 'rspec'
require 'spec_helper'
require 'databasedotcom'
require 'active_support/core_ext'

describe Databasedotcom::Soap::Messages do

  context "as a soap message builder" do
    
    it "should build a valid create message" do
      message = Databasedotcom::Soap::Messages.build_message("boing", "<mambo></mambo>", "boohoo", {})
      message.should =~ /<urn:sessionId>boohoo<\/urn:sessionId>/
      message.should =~ /<mambo><\/mambo>/
      message.should =~ /<urn:boing>/
    end

    it "should build a valid create message" do
      message = Databasedotcom::Soap::Messages.build_message("boing", "<mambo></mambo>", "boohoo", {:external_id_field => "<b>an_external_field</b>"})
      message.should =~ /<b>an_external_field<\/b>/
    end
  end

  context "::convert_to_soap_message" do
    module MySobjects
      class Boombox < Databasedotcom::Sobject::Sobject
        attr_accessor :Id, :Bort, :AnotherField, :NotCreateable, :NotUpdateable, :ADate
        
        def self.createable?(attr_name)
        	attr_name != "NotCreateable"
        end

        def self.updateable?(attr_name)
        	attr_name != "NotUpdateable"
        end

        def self.field_type(attr_name)
          attr_name == "ADate" ? "date" : "string"
        end

        def initialize(attrs = {})
        end
        
        def self.description 
          "Boombox"
        end
      end
    end

    it "should not return anything on invalid objects" do
      soap1 = Databasedotcom::Soap::Messages::convert_to_soap_message nil
      soap2 = Databasedotcom::Soap::Messages::convert_to_soap_message "Anything"
      soap3 = Databasedotcom::Soap::Messages::convert_to_soap_message ["Anything"]
      
      soap1.nil?.should be_true
      soap2.nil?.should be_true
      soap3.nil?.should be_true
    end

    it "should serialize all available fields" do
      boom = MySobjects::Boombox.new
      boom.Id = "foo"
      boom.Bort = "bort"
      boom.AnotherField = "baz"

      soap = Databasedotcom::Soap::Messages::convert_to_soap_message boom
      soap.should =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
      soap.should =~ /<Id>foo<\/Id>/
      soap.should =~ /<Bort>bort<\/Bort>/
      soap.should =~ /<AnotherField>baz<\/AnotherField>/
    end

    it "should serialize all available fields but only if value is set" do
      boom = MySobjects::Boombox.new
      boom.Id = "foo"
      boom.Bort = ""

      soap = Databasedotcom::Soap::Messages::convert_to_soap_message boom
      soap.should =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
      soap.should =~ /<Id>foo<\/Id>/
      soap.should_not =~ /<Bort><\/Bort>/
      soap.should_not =~ /<AnotherField><\/AnotherField>/
    end

    it "should serialize all available fields that are creatable soap action is create" do
      boom = MySobjects::Boombox.new
      boom.Id = "foo"
      boom.NotCreateable = "baz"
      boom.NotUpdateable = "baz"

      soap = Databasedotcom::Soap::Messages::convert_to_soap_message boom, :create
      soap.should =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
      soap.should =~ /<Id>foo<\/Id>/
      soap.should_not =~ /<NotCreateable>baz<\/NotCreateable>/
      soap.should =~ /<NotUpdateable>baz<\/NotUpdateable>/
    end

    it "should serialize all available fields that are updatable soap action is update" do
      boom = MySobjects::Boombox.new
      boom.Id = "foo"
      boom.NotCreateable = "baz"
      boom.NotUpdateable = "baz"

      soap = Databasedotcom::Soap::Messages::convert_to_soap_message boom, :update
      soap.should =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
      soap.should =~ /<Id>foo<\/Id>/
      soap.should =~ /<NotCreateable>baz<\/NotCreateable>/
      soap.should_not =~ /<NotUpdateable>baz<\/NotUpdateable>/
    end

    it "should only return <urn:ids> when action is :delete" do
      boom = MySobjects::Boombox.new
      boom.Id = "123456"
      boom.Bort = "bort"

      soap = Databasedotcom::Soap::Messages::convert_to_soap_message boom, :delete
      soap.should =~ /<urn:ids>123456<\/urn:ids>/
      soap.should_not =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
      soap.should_not =~ /<Bort>bort<\/Bort>/
    end

    it "should html escape html entities" do
      boom = MySobjects::Boombox.new
      boom.Id = "123456"
      boom.Bort = "This<br>is a text with<br>new br elements"

      soap = Databasedotcom::Soap::Messages::convert_to_soap_message boom, :update
      soap.should =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
      soap.should =~ /<Bort>This&lt;br&gt;is a text with&lt;br&gt;new br elements<\/Bort>/
    end

    context "handle datatype" do
      boom = MySobjects::Boombox.new
      boom.Id = "123456"

      it "date time should be convert to valid soap date if string is give" do
        boom.ADate = "2012-08-06 12:30:28 +0200"

        soap = Databasedotcom::Soap::Messages::convert_to_soap_message boom, :update
        soap.should =~ /<ADate>2012-08-06T12:30:28+02:00<\/ADate>/
      end

      it "date time should be convert to valid soap date if string is give" do
        boom.ADate = Time.now

        soap = Databasedotcom::Soap::Messages::convert_to_soap_message boom, :update
        soap.should =~ /<ADate>#{boom.ADate.iso8601}<\/ADate>/
      end
    end

    context "with the action :update" do 

      it "should create fields to null block" do
        boom = MySobjects::Boombox.new
        boom.Id = "foo"
  
        soap = Databasedotcom::Soap::Messages::convert_to_soap_message(boom, :update, {:fields_to_null => ["nope", "woop"]})
        soap.should =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
        soap.should =~ /<urn1:fieldsToNull>nope<\/urn1:fieldsToNull>/
        soap.should =~ /<urn1:fieldsToNull>woop<\/urn1:fieldsToNull>/
      end       

      it "should be able to handle empty :fields_to_null" do
        boom = MySobjects::Boombox.new
        boom.Id = "foo"
  
        soap = Databasedotcom::Soap::Messages::convert_to_soap_message(boom, :update, {})
        soap.should =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
        soap.should_not =~ /<urn1:fieldsToNull>nope<\/urn1:fieldsToNull>/
        soap.should_not =~ /<urn1:fieldsToNull>woop<\/urn1:fieldsToNull>/
      end  
  
      it "should add the id of the sobject to :update" do
        boom = MySobjects::Boombox.new
        boom.Id = "001D000000HTK3aIAH"
  
        soap = Databasedotcom::Soap::Messages::convert_to_soap_message(boom, :update, {})
        soap.should =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
        soap.should =~ /<urn1:Id>001D000000HTK3aIAH<\/urn1:Id>/
      end  

    end
  end
end