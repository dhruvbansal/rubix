require 'spec_helper'

describe "CRUD for user macros" do

  before do
    @hg1 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    ensure_save(@hg1)
    
    @h1  = Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@hg1])
    ensure_save(@h1)
  end

  after do
    ensure_destroy(@h1, @hg1)
  end
  
  it "should be able to create, update, and destroy a host" do
    integration_test
    
    Rubix::UserMacro.find(:name => 'rubix_spec_macro_1', :host_id => @h1.id).should be_nil
    
    um1 = Rubix::UserMacro.new(:name => 'rubix_spec_macro_1', :value => 'rubix_spec_value_1', :host_id => @h1.id)
    um1.save.should be_true

    id = um1.id
    id.should_not be_nil

    ensure_destroy(um1) do
      um2 = Rubix::UserMacro.find(:name => 'rubix_spec_macro_1', :host_id => @h1.id)
      um2.should_not be_nil

      um1.value = 'rubix_spec_value_2'
      um1.save.should be_true

      um2 = Rubix::UserMacro.find(:name => 'rubix_spec_macro_1', :host_id => @h1.id)
      um2.should_not be_nil
      um2.value.should == 'rubix_spec_value_2'

      um1.destroy
      Rubix::UserMacro.find(:name => 'rubix_spec_macro_1', :host_id => @h1.id).should be_nil
    end
  end
end
