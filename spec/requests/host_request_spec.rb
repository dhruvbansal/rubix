require 'spec_helper'

describe "CRUD for hosts" do

  before do
    @hg = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    @hg.save
  end

  after do
    @hg.destroy
  end
  
  it "should be able to create, update, and destroy a host" do
    integration_test
    
    Rubix::Host.find(:name => 'rubix_spec_host_1').should be_nil
    
    h = Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@hg])
    h.save
    Rubix::Host.find(:name => 'rubix_spec_host_1').should_not be_nil
    id = h.id
    id.should_not be_nil

    h.name = 'rubix_spec_host_2'
    h.update
    Rubix::Host.find(:id => id).name.should == 'rubix_spec_host_2'
    
    h.destroy
    Rubix::Host.find(:id => id).should be_nil
  end
end
