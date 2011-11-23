require 'spec_helper'

describe "CRUD for items" do

  before do
    @hg1 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    ensure_save(@hg1)
    
    @h1  = Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@hg1])
    ensure_save(@h1)

    @h2  = Rubix::Host.new(:name => 'rubix_spec_host_2', :host_groups => [@hg1])
    ensure_save(@h2)

    @a1 = Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @h1.id)
    ensure_save(@a1)

    @a2 = Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @h2.id)
    ensure_save(@a2)
  end

  after do
    ensure_destroy(@a1, @a2, @h1, @h2, @hg1)
  end
  
  it "should be able to create, update, and destroy an item" do
    integration_test
    
    Rubix::Item.find(:key => 'rubix.spec1', :host_id => @h1.id).should be_nil
    
    item1 = Rubix::Item.new(:key => 'rubix.spec1', :description => 'rubix item description 1', :host_id => @h1.id, :value_type => :character, :applications => [@a1])
    item1.save.should be_true
    id = item1.id
    id.should_not be_nil
    
    ensure_destroy(item1) do
      item2 = Rubix::Item.find(:key => 'rubix.spec1', :host_id => @h1.id)
      item2.should_not be_nil
      item2.host.name.should == @h1.name
      item2.key.should == 'rubix.spec1'
      item2.description.should == 'rubix item description 1'
      item2.value_type.should == :character
      item2.application_ids.should include(@a1.id)
      
      item1.key = 'rubix.spec2'
      item1.description = 'rubix item description 2'
      item1.value_type = :unsigned_int
      item1.host_id = @h2.id
      item1.applications = [@a2]
      item1.save.should be_true
      
      item2 = Rubix::Item.find(:key => 'rubix.spec2', :host_id => @h2.id)
      item2.should_not be_nil
      item2.host.name.should == @h2.name
      item2.key.should == 'rubix.spec2'
      item2.description.should == 'rubix item description 2'
      item2.value_type.should == :unsigned_int
      item2.application_ids.should include(@a2.id)
      
      item1.destroy
      Rubix::Item.find(:id => id, :host_id => @h1.id).should be_nil
      Rubix::Item.find(:id => id, :host_id => @h2.id).should be_nil
    end
  end
end
