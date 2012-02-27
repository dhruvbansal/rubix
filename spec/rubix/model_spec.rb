require 'spec_helper'

describe Rubix::Model do

  before do
    @model_wrapper = Class.new(Rubix::Model)
    @model_wrapper.zabbix_define :FOO, { :bar => 0, :booz => 1 }
    @model_wrapper.zabbix_attr :snap
    @model_wrapper.zabbix_attr :crackle, :default  => 'how'
    @model_wrapper.zabbix_attr :pop,     :required => true
  end

  it "can define attributes" do
    @model = @model_wrapper.new
    @model.snap.should be_nil
    @model.snap = 3
    @model.snap.should == 3
  end

  it "can define attributes with defaults" do
    @model_wrapper.new.crackle.should == 'how'
  end

  it "can define required attributs" do
    lambda { @model_wrapper.new.validate }.should raise_error(Rubix::ValidationError)
  end

  it "will define a lookup hash for translating between names and integer codes" do
    @model_wrapper::FOO_CODES[:bar].should  == 0
    @model_wrapper::FOO_CODES[:booz].should == 1
    @model_wrapper::FOO_NAMES[0].should     == :bar
    @model_wrapper::FOO_NAMES[1].should     == :booz
  end

  it "will define a lookup hash that acts as a Mash when looking up names to codes" do
    @model_wrapper::FOO_CODES[:bar].should   == 0
    @model_wrapper::FOO_CODES['bar'].should  == 0
  end

end
  
