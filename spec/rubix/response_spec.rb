require 'spec_helper'

describe Rubix::Response do

  def mock_response code, params={}
    mock("Mock Net::HTTPResponse instance").tap do |mr|
      mr.stub!(:code).and_return(code.to_s)
      mr.stub!(:body).and_return({"jsonrpc" => "2.0"}.merge(params).to_json)
    end
  end

  it "should regard any non-200 responses as errors" do
    Rubix::Response.new(mock_response(500)).error?.should be_true
    Rubix::Response.new(mock_response(404)).error?.should be_true
  end

  it "should regard 200 responses with an error hash as errors" do
    Rubix::Response.new(mock_response(200, 'error' => 'foobar')).error?.should be_true
  end

  it "should be able to tell when a successful response is empty" do
    Rubix::Response.new(mock_response(200, 'result' => '')).has_data?.should   be_false
    Rubix::Response.new(mock_response(200, 'result' => [])).has_data?.should   be_false
    Rubix::Response.new(mock_response(200, 'result' => {})).has_data?.should   be_false
    Rubix::Response.new(mock_response(200, 'result' => 'hi')).has_data?.should be_true
  end

  it "should be able to tell the type of a successful response" do
    Rubix::Response.new(mock_response(200, 'result' => 'foobar')).string?.should       be_true
    Rubix::Response.new(mock_response(200, 'result' => ['foobar'])).array?.should      be_true
    Rubix::Response.new(mock_response(200, 'result' => {'foo' => 'bar'})).hash?.should be_true
  end

end
  
