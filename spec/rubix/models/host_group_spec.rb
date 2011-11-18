require 'spec_helper'

describe Rubix::HostGroup do

  before do
    @name  = 'foobar'
    @id    = 100
    @group = Rubix::HostGroup.new(:name => @name)
    
    @successful_get_response    = mock_response([{'groupid' => @id, 'name' => @name, 'hosts' => [{'hostid' => 1}, {'hostid' => 2}]}])
    @successful_create_response = mock_response({'groupids' => [@id]})
    @empty_response             = mock_response
  end

  describe 'loading' do
    it "should retrieve properties for an existing host group" do
      @group.should_receive(:request).with('hostgroup.get', kind_of(Hash)).and_return(@successful_get_response)
      @group.exists?.should be_true
      @group.name.should == @name
      @group.id.should == @id
    end

    it "should recognize a host group does not exist" do
      @group.should_receive(:request).with('hostgroup.get', kind_of(Hash)).and_return(@empty_response)
      @group.exists?.should be_false
      @group.name.should == @name
      @group.id.should be_nil
    end
  end

  describe 'creating' do
    
    it "can successfully create a new host group" do
      @group.should_receive(:request).with('hostgroup.create', kind_of(Array)).and_return(@successful_create_response)
      @group.create
      @group.exists?.should be_true
      @group.id.should == @id
    end

    it "can handle an error" do
      @group.should_receive(:request).with('hostgroup.get', kind_of(Hash)).and_return(@empty_response)
      @group.should_receive(:request).with('hostgroup.create', kind_of(Array)).and_return(@empty_response)
      @group.create
      @group.exists?.should be_false
    end
    
  end

  describe 'updating' do
    
  end

  describe 'destroying' do
  end
  
end
