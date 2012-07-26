require 'rspec'
require 'spec_helper'
require 'databasedotcom'

describe Databasedotcom::Soap::Client do
#	module MySobjects
#      class Whizbang < Databasedotcom::Sobject::Sobject
#      end
#    end
#
#    module 
#
#    before do
# 
#     response = File.read(File.join(File.dirname(__FILE__), "../fixtures/sobject/sobject_describe_success_response.json"))
#      stub_request(:get, "https://na1.salesforce.com/services/data/v23.0/sobjects/Whizbang/describe").to_return(:body => response, :status => 200)
#      @client.sobject_module = MySobjects
#      MySobjects::Whizbang.client = @client
#      MySobjects::Whizbang.materialize("Whizbang")
#    end

  describe "logging" do
  	context "log request and response" do
    end
  end

  describe "create http socket" do
	context "with nil values" do
	  
	  before do
	    @soap_client = Databasedotcom::Soap::Client.new
	    @mock_client = double("client", :version => "23", :ca_file => nil, :verify_mode => nil)
	    @uri_mock = double("uri", :host => "yes", :port => 29)
	    @soap_client.rest_client = @mock_client
	  end

	  it "uses no settings of @mock_client" do
	  	socket = @soap_client.create_http_socket @uri_mock
	  	socket.use_ssl?.should be_true
	  	socket.ca_file.should be_nil
	  	socket.verify_mode.should be_nil
	  end
	end

	context "create with values" do

	  before do
	    @soap_client = Databasedotcom::Soap::Client.new
	    @mock_client = double("client", :version => "23", :ca_file => "wewe", :verify_mode => 2333)
	    @uri_mock = double("uri", :host => "yes", :port => 29)
	    @soap_client.rest_client = @mock_client
	  end

	  it "uses no settings of @mock_client" do
	  	socket = @soap_client.create_http_socket @uri_mock

	  	socket.ca_file == "wewe"
	  	socket.verify_mode.should == 2333
	  end
	end
  end

  describe "create http_request" do
  	before do
  	  uri_mock = double("uri", :host => "yes", :port => 29, :request_uri => "foobar.org", :host => "foobar")
	  mock_client = double("client", :debugging => false)

  	  @soap_client = Databasedotcom::Soap::Client.new
  	  @soap_client.rest_client = mock_client
  	  @default_hash = {:uri => uri_mock, :body => nil}
  	end

	it "should read body and body length" do
	  @default_hash[:body] = "bert bert bert"
	  request = @soap_client.create_http_request @default_hash

	  request.body.should == "bert bert bert"
	  request["Content-Length"].should == "14"
	  request["Content-Type"].should == "text/xml; charset=utf-8"
	  request["Host"].should == "foobar"
	  request["SOAPAction"].empty?.should be_true
  	end

	it "should read body and body length" do
	  @default_hash[:body] = "bert bert bert bert"
	  @default_hash[:action] = "create"
	  request = @soap_client.create_http_request @default_hash

	  request.body.should == "bert bert bert bert"
	  request["Content-Length"].should == "19"
	  request["Content-Type"].should == "text/xml; charset=utf-8"
	  request["Host"].should == "foobar"
	  request["SOAPAction"].should == "create"
  	end

  	it "should throw without body" do
  	  lambda { 
  	  	request = @soap_client.create_http_request @default_hash
  	  }.should raise_error(ArgumentError)
  	end
  end
end