require 'spec_helper'

describe "CRUD for items" do

  before do
    @hg1 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    @hg1.save
    
    @h1  = Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@hg1])
    @h1.save

    @h2  = Rubix::Host.new(:name => 'rubix_spec_host_2', :host_groups => [@hg1])
    @h2.save

    @a1 = Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @h1.id)
    @a1.save

    @a2 = Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @h2.id)
    @a2.save
    
  end

  after do
    @a1.destroy
    @a2.destroy
    @h1.destroy
    @h2.destroy
    @hg1.destroy
  end
  
  it "should be able to create, update, and destroy an item" do
    integration_test
    
    Rubix::Item.find(:key => 'rubix.spec1', :host_id => @h1.id).should be_nil
    
    item = Rubix::Item.new(:key => 'rubix.spec1', :description => 'rubix item description 1', :host_id => @h1.id, :value_type => :character, :applications => [@a1])
    item.save
    
    new_i = Rubix::Item.find(:key => 'rubix.spec1', :host_id => @h1.id)
    new_i.should_not be_nil
    new_i.host.name.should == @h1.name
    new_i.key.should == 'rubix.spec1'
    new_i.description.should == 'rubix item description 1'
    new_i.value_type.should == :character
    new_i.application_ids.should include(@a1.id)
    
    id = item.id
    id.should_not be_nil

    item.key = 'rubix.spec2'
    item.description = 'rubix item description 2'
    item.value_type = :unsigned_int
    item.host_id = @h2.id
    item.applications = [@a2]
    item.update

    new_i = Rubix::Item.find(:key => 'rubix.spec2', :host_id => @h2.id)
    new_i.should_not be_nil
    new_i.host.name.should == @h2.name
    new_i.key.should == 'rubix.spec2'
    new_i.description.should == 'rubix item description 2'
    new_i.value_type.should == :unsigned_int
    new_i.application_ids.should include(@a2.id)
    
    item.destroy
    Rubix::Item.find(:id => id, :host_id => @h1.id).should be_nil
  end
end
