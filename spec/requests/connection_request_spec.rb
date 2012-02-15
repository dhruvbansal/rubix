require 'spec_helper'

describe Rubix::Connection do

  before do
    integration_test
  end

  after do
    truncate_all_tables
  end

  it "can perform an authorized GET request to the homepage" do
    response = Rubix.connection.web_request("GET", "/")
    response.should_not be_nil
    response.code.to_i.should == 200
    response.body.should_not include('guest')
    response.body.should     include($RUBIX_INTEGRATION_TEST['username'])
  end

  it "can perform an authorized POST request to the homepage" do
    response = Rubix.connection.web_request("POST", "/", :foo => 'bar', :baz => 'buzz')
    response.should_not be_nil
    response.code.to_i.should == 200
    response.body.should_not include('guest')
    response.body.should     include($RUBIX_INTEGRATION_TEST['username'])
  end

  it "can perform an authorized multipart POST request to the homepage" do
    response = Rubix.connection.web_request("POST", "/", :foo => File.new(data_path('test_template.xml')))
    response.should_not be_nil
    response.code.to_i.should == 200
    response.body.should_not include('guest')
    response.body.should     include($RUBIX_INTEGRATION_TEST['username'])
  end
  
end

