require 'rspec'
require 'spec_helper'
require 'databasedotcom'


describe Databasedotcom::Soap::Client do

  describe "web requests" do
    context "against the soap api" do
      before do
        @soap_client = Databasedotcom::Soap::Client.new
        @soap_client.rest_client = double("client", :debugging => false, :instance_url => "http://foobar.com", :version => 21, :ca_file => nil, :verify_mode => nil)
      end

      it "should send a simple request using parameters from the rest_client" do
        stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:headers=>{ 'SOAPAction' => '' }).to_return(:body => "foobar response")
        response = @soap_client.http_request(:body => "hooba")

        response.body.should == "foobar response"
      end

      it "should send the body and set its length" do
        stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:body => "hoobaaa", :headers=>{ "Content-Length" => "7" }).to_return(:body => "foobar response", :status => 200)
        response = @soap_client.http_request(:body => "hoobaaa")
        
        response.body.should == "foobar response"
        response.code.should == "200"
      end

      it "should create a request with the correct headers" do
        stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:headers=>{ "Content-Type" => "text/xml; charset=utf-8", "Content-Length"=> "6", "SOAPAction"   => "jump!", "Host" => "foobar.com" }).to_return(:body => "foobar response", :status => 200)
        response = @soap_client.http_request(:body => "hooaaa", :action=> "jump!")
        
        response.body.should == "foobar response"
        response.code.should == "200"
      end

      it "should throw without body" do
        lambda { 
           request = @soap_client.http_request
        }.should raise_error(ArgumentError)
      end

      it "should throw error when the rest_client is not set" do
        @soap_client = Databasedotcom::Soap::Client.new
        lambda { 
           request = @soap_client.http_request(:body => "foobar")
        }.should raise_error(ArgumentError)
      end
    end

    describe "insert action" do
      module MySobjects
        class Boombox < Databasedotcom::Sobject::Sobject
          attr_accessor :Id

          def initialize(attrs = {})
          end

          attr_accessor :bort

          def self.description 
            "Boombox"
          end
        end
      end

      context "with invalid inputs" do
        before do
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").to_raise(StandardError)
          @rest_client = double("client", :debugging => false, :instance_url => "http://foobar.com", :version => 21, :ca_file => nil, :verify_mode => nil, :oauth_token => "set to nothing")
          @soap_client = Databasedotcom::Soap::Client.new
        end

        it "should not do anything when given an empty array of sobjects" do
          ret = @soap_client.insert
          ret.empty?.should be_true
        end

        it "should not do anything when giving crap objects" do
          ret = @soap_client.insert [1, "adkasdlsa", nil, true]
          ret.empty?.should be_true
        end

        it "should not do anything when giving crap objects" do
          ret = @soap_client.insert "sadasda"
          ret.empty?.should be_true
        end

        it "should not accept objects that do not have the rest_client set" do
          boombox = MySobjects::Boombox.new
          boombox.client = nil
          lambda {
            @soap_client.insert boombox
          }.should raise_error(ArgumentError)
        end
      end

      context "with valid inputs" do
        before do
          @rest_client = double("client", :debugging => false, :instance_url => "http://foobar.com", :version => 21, :ca_file => nil, :verify_mode => nil, :oauth_token => "set to nothing")
          @soap_client = Databasedotcom::Soap::Client.new
          
          @boom_boxes = 5.times.map{ |i| 
            box = MySobjects::Boombox.new
            box.client = @rest_client
            box.bort = "item\##{i}"
            box
          }
        end

        it "should set ids when returning positive results from a single request" do
          @response_body = File.read(File.join(File.dirname(__FILE__), "../../fixtures/soap/create_positive_response_5_items.xml"))
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:body => /<urn:create/).to_return(:body => @response_body)

          @boom_boxes[2].Id.nil?.should be_true

          errors = @soap_client.insert @boom_boxes

          @boom_boxes[0].Id.should == "eins"
          @boom_boxes[1].Id.should == "zwei"
          @boom_boxes[2].Id.should == "drei"
          @boom_boxes[3].Id.should == "vier"
          @boom_boxes[4].Id.should == "fuenf"
          errors.count.should == 0
        end        

        it "should set ids when returning positive results from two requests" do
          @soap_client.record_limit = 3
          @response_bodies = File.read(File.join(File.dirname(__FILE__), "../../fixtures/soap/create_positive_response_5_items_in_two_requests.xml")).split("::::::")
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:body => /item\#2/).to_return(:body => @response_bodies[0])
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:body => /item\#4/).to_return(:body => @response_bodies[1])

          @boom_boxes[2].Id.nil?.should be_true

          @soap_client.insert @boom_boxes

          @boom_boxes[0].Id.should == "eins"
          @boom_boxes[1].Id.should == "zwei"
          @boom_boxes[2].Id.should == "drei"
          @boom_boxes[3].Id.should == "vier"
          @boom_boxes[4].Id.should == "fuenf"
        end

        it "should set ids when returning positive results from two requests when array_of_sobjects contains crap" do
          @soap_client.record_limit = 3
          @response_bodies = File.read(File.join(File.dirname(__FILE__), "../../fixtures/soap/create_positive_response_5_items_in_two_requests.xml")).split("::::::")
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:body => /item\#2/).to_return(:body => @response_bodies[0])
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:body => /item\#4/).to_return(:body => @response_bodies[1])

          @boom_boxes[2].Id.nil?.should be_true
          @boom_boxes.insert 3, "this element is crap"
          @boom_boxes.insert 5, nil

          @soap_client.insert @boom_boxes
          
          @boom_boxes[0].Id.should == "eins"
          @boom_boxes[1].Id.should == "zwei"
          @boom_boxes[2].Id.should == "drei"
          @boom_boxes[4].Id.should == "vier"
          @boom_boxes[6].Id.should == "fuenf"
        end

        it "should not set ids when returning negative results and set the errors correctly" do
          @response_body = File.read(File.join(File.dirname(__FILE__), "../../fixtures/soap/create_positive_and_negative_response_5_items.xml"))
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").to_return(:body => @response_body)

          @boom_boxes[2].Id.nil?.should be_true

          errors = @soap_client.insert @boom_boxes

          @boom_boxes[0].Id.should == "eins"
          @boom_boxes[1].Id.should == "zwei"
          @boom_boxes[2].Id.nil?.should be_true
          @boom_boxes[3].Id.should == "vier"
          @boom_boxes[4].Id.nil?.should be_true
          errors.count.should == 2
          errors[0].message.should =~ /meh!/
          errors[0].s_object.bort.should == "item#2"
          errors[1].message.should =~ /this sucks!/
          errors[1].s_object.bort.should == "item#4"
        end 
      end
    end

    describe "delete action" do
      module MySobjects
        class Boombox < Databasedotcom::Sobject::Sobject
          attr_accessor :Id

          def initialize(attrs = {})
          end

          attr_accessor :bort

          def self.description 
            "Boombox"
          end
        end
      end

      context "with invalid inputs" do
        before do
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").to_raise(StandardError)
          @rest_client = double("client", :debugging => false, :instance_url => "http://foobar.com", :version => 21, :ca_file => nil, :verify_mode => nil, :oauth_token => "set to nothing")
          @soap_client = Databasedotcom::Soap::Client.new
        end

        it "should not do anything when given an empty array of sobjects" do
          ret = @soap_client.delete
          ret.empty?.should be_true
        end

        it "should not do anything when giving crap objects" do
          ret = @soap_client.delete [1, "adkasdlsa", nil, true]
          ret.empty?.should be_true
        end

        it "should not do anything when giving crap objects" do
          ret = @soap_client.delete "sadasda"
          ret.empty?.should be_true
        end

        it "should not accept objects that do not have the rest_client set" do
          boombox = MySobjects::Boombox.new
          boombox.client = nil
          lambda {
            @soap_client.delete boombox
          }.should raise_error(ArgumentError)
        end
      end

      context "with valid inputs" do
        before do
          @rest_client = double("client", :debugging => false, :instance_url => "http://foobar.com", :version => 21, :ca_file => nil, :verify_mode => nil, :oauth_token => "set to nothing")
          @soap_client = Databasedotcom::Soap::Client.new
          
          ids = %w(eins zwei drei vier fuenf)
          @boom_boxes = 5.times.map{ |i| 
            box = MySobjects::Boombox.new
            box.client = @rest_client
            box.bort = "item\##{i}"
            box.Id = ids[i]
            box
          }
        end

        it "should set ids when returning positive results from a single request" do
          @response_body = File.read(File.join(File.dirname(__FILE__), "../../fixtures/soap/delete_positive_response_5_items.xml"))
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:body => /<urn:delete/).to_return(:body => @response_body)

          @boom_boxes[1].Id.should == "zwei"

          errors = @soap_client.delete @boom_boxes

          @boom_boxes[0].Id.nil?.should be_true
          @boom_boxes[1].Id.nil?.should be_true
          @boom_boxes[2].Id.nil?.should be_true
          @boom_boxes[3].Id.nil?.should be_true
          @boom_boxes[4].Id.nil?.should be_true
          errors.count.should == 0
        end        

        it "should set ids when returning positive results from two requests" do
          @soap_client.record_limit = 3
          @response_bodies = File.read(File.join(File.dirname(__FILE__), "../../fixtures/soap/delete_positive_response_5_items_in_two_requests.xml")).split("::::::")
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:body => /eins/).to_return(:body => @response_bodies[0])
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:body => /fuenf/).to_return(:body => @response_bodies[1])

          @boom_boxes[1].Id.should == "zwei"

          @soap_client.delete @boom_boxes

          @boom_boxes[0].Id.nil?.should be_true
          @boom_boxes[1].Id.nil?.should be_true
          @boom_boxes[2].Id.nil?.should be_true
          @boom_boxes[3].Id.nil?.should be_true
          @boom_boxes[4].Id.nil?.should be_true
        end

        it "should set ids when returning positive results from two requests when array_of_sobjects contains crap" do
          @soap_client.record_limit = 3
          @response_bodies = File.read(File.join(File.dirname(__FILE__), "../../fixtures/soap/delete_positive_response_5_items_in_two_requests.xml")).split("::::::")
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:body => /eins/).to_return(:body => @response_bodies[0])
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").with(:body => /fuenf/).to_return(:body => @response_bodies[1])

          @boom_boxes[1].Id.should == "zwei"
          @boom_boxes.insert 3, "this element is crap"
          @boom_boxes.insert 5, nil

          @soap_client.delete @boom_boxes

          @boom_boxes[0].Id.nil?.should be_true
          @boom_boxes[1].Id.nil?.should be_true
          @boom_boxes[2].Id.nil?.should be_true
          @boom_boxes[4].Id.nil?.should be_true
          @boom_boxes[6].Id.nil?.should be_true
        end

        it "should not set ids when returning negative results and set the errors correctly" do
          @response_body = File.read(File.join(File.dirname(__FILE__), "../../fixtures/soap/delete_positive_and_negative_response_5_items.xml"))
          stub_request(:post, "https://foobar.com:80/services/Soap/c/21").to_return(:body => @response_body)

          @boom_boxes[1].Id.should == "zwei"

          errors = @soap_client.delete @boom_boxes

          @boom_boxes[0].Id.nil?.should be_true
          @boom_boxes[1].Id.nil?.should be_true
          @boom_boxes[2].Id.should == "drei"
          @boom_boxes[3].Id.nil?.should be_true
          @boom_boxes[4].Id.should == "fuenf"
          errors.count.should == 2
          errors[0].message.should =~ /meh!/
          errors[0].s_object.Id.should == "drei"
          errors[1].message.should =~ /this sucks!/
          errors[1].s_object.Id.should == "fuenf"
        end 
      end
    end
  end
end