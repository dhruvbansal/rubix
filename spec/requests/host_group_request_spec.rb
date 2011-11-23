require 'spec_helper'

describe "CRUD for host groups" do

  it "should be able to create, update, and destroy a host group" do
    integration_test
    
    Rubix::HostGroup.find(:name => 'rubix_spec_host_group_1').should be_nil
    
    hg1 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    hg1.save.should be_true
    id = hg1.id
    id.should_not be_nil

    ensure_destroy(hg1) do
      hg2 = Rubix::HostGroup.find(:name => 'rubix_spec_host_group_1')
      hg2.should_not be_nil
      hg2.name.should == 'rubix_spec_host_group_1'
      
      hg1.name = 'rubix_spec_host_group_2'
      hg1.save.should be_true

      hg2 = Rubix::HostGroup.find(:name => 'rubix_spec_host_group_2')
      hg2.should_not be_nil
      hg2.name.should == 'rubix_spec_host_group_2'

      hg1.destroy
      Rubix::HostGroup.find(:id => id).should be_nil
    end
  end
end
