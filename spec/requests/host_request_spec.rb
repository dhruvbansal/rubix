require 'spec_helper'

describe "CRUD for hosts" do

  before do
    @hg1 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    ensure_save(@hg1)

    @hg2 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_2')
    ensure_save(@hg2)
    
    @t1 = Rubix::Template.new(:name => 'rubix_spec_template_1', :host_groups => [@hg1])
    ensure_save(@t1)

    @t2 = Rubix::Template.new(:name => 'rubix_spec_template_2', :host_groups => [@hg2])
    ensure_save(@t2)

    @um1 = Rubix::UserMacro.new(:name => 'rubix_spec_macro_1', :value => 'rubix_spec_value_1')
    
  end

  after do
    ensure_destroy(@um1, @t1, @t2, @hg1, @hg2)
  end
  
  it "should be able to create, update, and destroy a host" do
    integration_test
    
    Rubix::Host.find(:name => 'rubix_spec_host_1').should be_nil
    
    h1 = Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@hg1], :templates => [@t1], :user_macros => [@um1])
    h1.save.should be_true
    id = h1.id
    id.should_not be_nil
    
    ensure_destroy(h1) do
      h2 = Rubix::Host.find(:name => 'rubix_spec_host_1')
      h2.should_not be_nil
      h2.template_ids.should include(@t1.id)
      h2.host_group_ids.should include(@hg1.id)
      h2.user_macros.size.should == 1
      h2.user_macros.first.name.should  == 'RUBIX_SPEC_MACRO_1'
      h2.user_macros.first.value.should == 'rubix_spec_value_1'
      
      h1.name = 'rubix_spec_host_2'
      h1.host_groups = [@hg2]
      h1.templates = [@t2]
      h1.save.should be_true
      
      h2 = Rubix::Host.find(:name => 'rubix_spec_host_2')
      h2.should_not be_nil
      h2.template_ids.should include(@t2.id)
      h2.host_group_ids.should include(@hg2.id)
      h2.user_macros.size.should == 1
      h2.user_macros.first.name.should  == 'RUBIX_SPEC_MACRO_1'
      h2.user_macros.first.value.should == 'rubix_spec_value_1'

      h1.destroy
      Rubix::Host.find(:id => id).should be_nil
    end
    
  end
end
