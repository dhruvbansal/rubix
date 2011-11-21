require 'spec_helper'

describe "CRUD for hosts" do

  before do
    @hg = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    @hg.save
    
    @h1  = Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@hg])
    @h1.save

    @h2  = Rubix::Host.new(:name => 'rubix_spec_host_2', :host_groups => [@hg])
    @h2.save
  end

  after do
    @h1.destroy
    @h2.destroy
    @hg.destroy
  end
  
  it "should be able to create, update, and destroy a host" do
    integration_test
    
    Rubix::Application.find(:name => 'rubix_spec_app_1', :host_id => @h1.id).should be_nil
    
    app = Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @h1.id)
    app.save
    new_a = Rubix::Application.find(:name => 'rubix_spec_app_1', :host_id => @h1.id)
    new_a.should_not be_nil
    new_a.id.should == app.id
    new_a.host_id.should == @h1.id
    id = app.id
    id.should_not be_nil

    app.name = 'rubix_spec_app_2'
    app.update
    new_a = Rubix::Application.find(:id => id, :name => 'rubix_spec_app_2', :host_id => @h1.id)
    new_a.should_not be_nil
    new_a.name.should == 'rubix_spec_app_2'
    
    app.destroy
    Rubix::Application.find(:id => id, :host_id => @h1.id).should be_nil
  end
end
