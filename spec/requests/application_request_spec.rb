require 'spec_helper'

describe "CRUD for hosts" do

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
  
  it "should be able to create, update, and destroy a host" do
    integration_test
    
    Rubix::Application.find(:name => 'rubix_spec_app_1', :host_id => @h.id).should be_nil
    
    app = Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @h.id)
    app.save
    Rubix::Application.find(:name => 'rubix_spec_app_1', :host_id => @h.id).should_not be_nil
    id = app.id
    id.should_not be_nil

    app.name = 'rubix_spec_app_2'
    app.update
    Rubix::Application.find(:id => id, :host_id => @h.id).name.should == 'rubix_spec_app_2'
    
    app.destroy
    Rubix::Application.find(:id => id, :host_id => @h.id).should be_nil
  end
end
