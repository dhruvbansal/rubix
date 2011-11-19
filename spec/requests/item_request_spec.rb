require 'spec_helper'

describe "CRUD for items" do

  before do
    @hg = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    @hg.save
    
    @h  = Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@hg])
    @h.save
  end

  after do
    @h.destroy
    @hg.destroy
  end
  
  it "should be able to create, update, and destroy an item" do
    integration_test
    
    Rubix::Item.find(:key => 'rubix.spec1', :host_id => @h.id).should be_nil
    
    item = Rubix::Item.new(:key => 'rubix.spec1', :value => 'rubix_spec_value_1', :host_id => @h.id)
    item.save
    Rubix::Item.find(:key => 'rubix.spec1', :host_id => @h.id).should_not be_nil
    id = item.id
    id.should_not be_nil

    item.key = 'rubix.spec2'
    item.update
    Rubix::Item.find(:id => id, :host_id => @h.id).key.should == 'rubix.spec2'
    
    item.destroy
    Rubix::Item.find(:id => id, :host_id => @h.id).should be_nil
  end
end
