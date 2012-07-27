require 'rspec'
require 'spec_helper'
require 'databasedotcom'
require 'active_support/core_ext'

describe Databasedotcom::Soap::Messages do

  context "as a soap message builder" do
    
    it "should build a valid insert message" do
      insert_message = Databasedotcom::Soap::Messages.build_insert({:session_id => "boohoo", :body => "<mambo></mambo>"})
      insert_message.should =~ /<urn:sessionId>boohoo<\/urn:sessionId>/
      insert_message.should =~ /<mambo><\/mambo>/
      insert_message.should =~ /<urn:create>/
    end

    it "should build a valid delete message" do
      delete_message = Databasedotcom::Soap::Messages.build_delete({:session_id => "hoooboo", :body => "<tango></tango>"})
      delete_message.should =~ /<urn:sessionId>hoooboo<\/urn:sessionId>/
      delete_message.should =~ /<tango><\/tango>/
      delete_message.should =~ /<urn:delete>/
    end  

    it "should build a valid update message" do
      update_message = Databasedotcom::Soap::Messages.build_update({:session_id => "update!", :body => "<chacha></chacha>"})
      update_message.should =~/<urn:sessionId>update!<\/urn:sessionId>/
      update_message.should =~ /<chacha><\/chacha>/
      update_message.should =~ /<urn:update>/
    end

    it "should build a valid upsert message" do
      upsert_message = Databasedotcom::Soap::Messages.build_upsert({:external_id_field => "external23", :session_id => "upsert!", :body => "<wubwub></wubwub>"})
      upsert_message.should =~/<urn:sessionId>upsert!<\/urn:sessionId>/
      upsert_message.should =~ /<wubwub><\/wubwub>/
      upsert_message.should =~ /<urn:upsert>/
      upsert_message.should =~ /<urn:externalIDFieldName>external23<\/urn:externalIDFieldName>/
    end
  end

  context "::convert_to_soap_message" do
    module MySobjects
      class Boombox < Databasedotcom::Sobject::Sobject
        attr_accessor :Id, :Bort, :AnotherField, :NotCreateable, :NotUpdateable
        
        def createable?(attr_name)
        	attr_name != "NotCreateable"
        end

        def updateable?(attr_name)
        	attr_name != "NotUpdateable"
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

      soap = Databasedotcom::Soap::Messages::convert_to_soap_message boom
      soap.should =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
      soap.should =~ /<Id>foo<\/Id>/
      soap.should_not =~ /<Bort>bort<\/Bort>/
      soap.should_not =~ /<AnotherField>baz<\/AnotherField>/
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

    it "should serialize all available fields that are updatable soap action is update" do
      boom = MySobjects::Boombox.new
      boom.Id = "123456"
      boom.Bort = "bort"

      soap = Databasedotcom::Soap::Messages::convert_to_soap_message boom, :delete
      soap.should =~ /<urn:ids>123456<\/urn:ids>/
      soap.should_not =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
      soap.should_not =~ /<Bort>bort<\/Bort>/
    end

    it "should insert custom block" do
      boom = MySobjects::Boombox.new
      boom.Id = "foo"
      boom.Bort = "bort"
      boom.AnotherField = "baz"

      soap = Databasedotcom::Soap::Messages::convert_to_soap_message(boom, :create) {|s| "<customblock>" }
      soap.should =~ /<urn:sObjects xsi:type=\"urn1:Boombox/
      soap.should =~ /<Id>foo<\/Id>/
      soap.should =~ /<Bort>bort<\/Bort>/
      soap.should =~ /<customblock>/
    end        
  end
end