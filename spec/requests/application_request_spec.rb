require 'spec_helper'

describe "CRUD for hosts" do

  before do
    @hg = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    ensure_save(@hg)
    
    @h1  = Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@hg])
    ensure_save(@h1)

    @h2  = Rubix::Host.new(:name => 'rubix_spec_host_2', :host_groups => [@hg])
    ensure_save(@h2)
  end

  after do
    ensure_destroy(@h1, @h2, @hg)
  end
  
  it "should be able to create, update, and destroy a host" do
    integration_test
    
    Rubix::Application.find(:name => 'rubix_spec_app_1', :host_id => @h1.id).should be_nil
    
    app1 = Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @h1.id)
    app1.save.should be_true
    id = app1.id
    id.should_not be_nil
    
    ensure_destroy(app1) do
      
      app2 = Rubix::Application.find(:name => 'rubix_spec_app_1', :host_id => @h1.id)
      app2.should_not be_nil
      app2.id.should == app1.id
      app2.host_id.should == @h1.id
      
      app1.name = 'rubix_spec_app_2'
      app1.save.should be_true
      
      app2 = Rubix::Application.find(:id => id, :name => 'rubix_spec_app_2', :host_id => @h1.id)
      app2.should_not be_nil
      app2.name.should == 'rubix_spec_app_2'
      
      app1.destroy.should be_true
      Rubix::Application.find(:id => id, :host_id => @h1.id).should be_nil
      Rubix::Application.find(:id => id, :host_id => @h2.id).should be_nil
    end
  end
end
