require 'spec_helper'

describe "CRUD for host groups" do

  it "should be able to create, update, and destroy a host group" do
    integration_test
    
    Rubix::HostGroup.find(:name => 'rubix_spec_host_group_1').should be_nil
    
    hg = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    hg.save
    Rubix::HostGroup.find(:name => 'rubix_spec_host_group_1').should_not be_nil
    id = hg.id
    id.should_not be_nil

    hg.name = 'rubix_spec_host_group_2'
    hg.update
    Rubix::HostGroup.find(:id => id).name.should == 'rubix_spec_host_group_2'
    
    hg.destroy
    Rubix::HostGroup.find(:id => id).should be_nil
  end
end
