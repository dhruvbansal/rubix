require 'spec_helper'

describe Rubix::Connection do

  before do
    
    @mock_server   = mock("Net::HTTP instance")
    Net::HTTP.stub!(:new).and_return(@mock_server)
    
    @mock_response = mock("Net::HTTP::Response instance")
    @mock_server.stub!(:request).and_return(@mock_response)
    @mock_response.stub!(:code).and_return('200')
    

    @good_auth_response = '{"result": "auth_token"}'
    @blah_response      = '{"result": "bar"}'

    @mock_response.stub!(:body).and_return(@blah_response)
    
    @connection = Rubix::Connection.new('localhost/api.php', 'username', 'password')
  end

  describe "sending API requests" do

    it "should attempt to authorize itself without being asked" do
      @connection.should_receive(:authorize!)
      @connection.request('foobar', {})
    end

    it "should not repeatedly authorize itself" do
      @mock_response.stub!(:body).and_return(@good_auth_response, @blah_response, @blah_response)
      @connection.request('foobar', {})
      @connection.should_not_receive(:authorize!)
      @connection.request('foobar', {})
    end

    it "should increment its request ID" do
      @mock_response.stub!(:body).and_return(@good_auth_response, @blah_response, @blah_response)
      @connection.request('foobar', {})
      @connection.request('foobar', {})
      @connection.request_id.should == 3 # it's the number used for the *next* request
    end

    it "should refresh its authorization credentials if they are deleted automatically" do
      @mock_response.stub!(:body).and_return('{"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid params.","data":"Not authorized"},"id":4}')
      @connection.should_receive(:authorize!)
      @connection.request('foobar', {})
    end

  end

  describe "sending web requests" do

    it "should attempt to authorize itself without being asked" do
      @connection.should_receive(:authorize!)
      @connection.web_request("GET", "/")
    end

    it "should not repeatedly authorize itself" do
      @mock_response.stub!(:body).and_return(@good_auth_response, @blah_response, @blah_response)
      @connection.web_request("GET", "/")
      @connection.should_not_receive(:authorize!)
      @connection.web_request("GET", "/")
    end

    it "should NOT increment its request ID" do
      @mock_response.stub!(:body).and_return(@good_auth_response, @blah_response, @blah_response)
      @connection.web_request("GET", "/")
      @connection.web_request("GET", "/")
      @connection.request_id.should == 1
    end

  end
  
end
