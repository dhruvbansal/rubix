require 'spec_helper'
require 'multi_json'

describe Rubix::Response do

  def response code, params={}
    Rubix::Response.new(double("Net::HTTPResponse instance", code: code.to_s, body: MultiJson.dump({"jsonrpc" => "2.0"}.merge(params))))
  end

  context "a 5xx response" do
    subject { response(500) }
    its(:non_200?) { should be_true }
    its(:error?)   { should be_true }
  end

  context "a 4xx response" do
    subject { response(400) }
    its(:non_200?) { should be_true }
    its(:error?)   { should be_true }
  end

  context "a 200 response" do
    subject { response(200) }
    its(:non_200?) { should be_false }
    context "with a result that is" do
      context "an empty String" do
        subject { response(200, 'result' => '') }
        its(:has_data?) { should be_false }
        its(:string?)   { should be_false }
        its(:array?)    { should be_false }
        its(:hash?)     { should be_false }
      end
      context "an empty Array" do
        subject { response(200, 'result' => []) }
        its(:has_data?) { should be_false }
        its(:string?)   { should be_false }
        its(:array?)    { should be_false }
        its(:hash?)     { should be_false }
      end
      context "an empty Hash" do
        subject { response(200, 'result' => {}) }
        its(:has_data?) { should be_false }
        its(:string?)   { should be_false }
        its(:array?)    { should be_false }
        its(:hash?)     { should be_false }
      end
      context "a String" do
        subject { response(200, 'result' => 'hello there') }
        its(:has_data?) { should be_true }
        its(:string?)   { should be_true  }
        its(:array?)    { should be_false }
        its(:hash?)     { should be_false }
        its(:result)    { should == 'hello there' }
      end
      context "an Array" do
        subject { response(200, 'result' => ['hello', 'there']) }
        its(:has_data?) { should be_true }
        its(:string?)   { should be_false }
        its(:array?)    { should be_true  }
        its(:hash?)     { should be_false }
        its(:result)    { should == [ 'hello', 'there' ] }
      end
      context "a Hash" do
        subject { response(200, 'result' => {'hello' => 'there'}) }
        its(:has_data?) { should be_true  }
        its(:string?)   { should be_false }
        its(:array?)    { should be_false }
        its(:hash?)     { should be_true  }
        its(:result)    { should == { 'hello' => 'there' } }
      end
      context "with an error message" do
        subject { response(200, 'error' => { 'message' => 'foobar'}) }
        its(:has_data?) { should be_false }
        its(:string?)   { should be_false }
        its(:array?)    { should be_false }
        its(:hash?)     { should be_false }
        its(:error?)    { should be_true }
        its(:error_message) { should == 'foobar' }
      end
    end
  end
end
