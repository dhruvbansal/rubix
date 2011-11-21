require 'spec_helper'

describe "CRUD for hosts" do

  before do
    @hg1 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    @hg1.save

    @hg2 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_2')
    @hg2.save
    
    @t1 = Rubix::Template.new(:name => 'rubix_spec_template_1', :host_groups => [@hg1])
    @t1.save

    @t2 = Rubix::Template.new(:name => 'rubix_spec_template_2', :host_groups => [@hg2])
    @t2.save

    @um1 = Rubix::UserMacro.new(:name => 'rubix_spec_macro_1', :value => 'rubix_spec_value_1')
    @um2 = Rubix::UserMacro.new(:name => 'rubix_spec_macro_2', :value => 'rubix_spec_value_2')
    
  end

  after do
    @t1.destroy
    @t2.destroy
    @hg1.destroy
    @hg2.destroy
  end
  
  it "should be able to create, update, and destroy a host" do
    integration_test
    
    Rubix::Host.find(:name => 'rubix_spec_host_1').should be_nil
    
    h = Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@hg1], :templates => [@t1], :user_macros => [@um1])
    h.save
    begin
      new_h = Rubix::Host.find(:name => 'rubix_spec_host_1')
      new_h.should_not be_nil
      new_h.template_ids.should include(@t1.id)
      new_h.host_group_ids.should include(@hg1.id)
      new_h.user_macros.size.should == 1
      new_h.user_macros.first.name.should  == 'RUBIX_SPEC_MACRO_1'
      new_h.user_macros.first.value.should == 'rubix_spec_value_1'
      
      id = h.id
      id.should_not be_nil
      
      h.name = 'rubix_spec_host_2'
      h.host_groups = [@hg2]
      h.templates = [@t2]
      h.user_macros = [@um2]
      h.update
      
      new_h = Rubix::Host.find(:name => 'rubix_spec_host_2')
      new_h.should_not be_nil
      new_h.template_ids.should include(@t2.id)
      new_h.host_group_ids.should include(@hg2.id)
      new_h.user_macros.size.should == 1
      new_h.user_macros.first.name.should  == 'RUBIX_SPEC_MACRO_2'
      new_h.user_macros.first.value.should == 'rubix_spec_value_2'
    rescue => e
      puts "#{e.class} -- #{e.message}"
      puts e.backtrace
    ensure
      h.destroy
    end
    Rubix::Host.find(:id => id).should be_nil
  end
end
