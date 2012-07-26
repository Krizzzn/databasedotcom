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

end