require 'spec_helper'

describe "CRUD for templates" do

  before do
    @hg1 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    @hg1.save

    @hg2 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_2')
    @hg2.save
    
  end

  after do
    @hg1.destroy
    @hg2.destroy
  end

  it "should be able to create, update, and destroy a template" do
    integration_test
    
    Rubix::Template.find(:name => 'rubix_spec_template_1').should be_nil
    
    t = Rubix::Template.new(:name => 'rubix_spec_template_1', :host_groups => [@hg1])
    t.save
    
    new_t = Rubix::Template.find(:name => 'rubix_spec_template_1')
    new_t.should_not be_nil
    new_t.id.should == t.id
    new_t.host_group_ids.should include(@hg1.id)
    id = t.id
    id.should_not be_nil

    t.name = 'rubix_spec_template_2'
    t.host_groups = [@hg2]
    t.update

    new_t = Rubix::Template.find(:id => id)
    new_t.name.should == 'rubix_spec_template_2'
    new_t.host_group_ids.should_not include(@hg1.id)
    new_t.host_group_ids.should     include(@hg2.id)
    
    t.destroy
    Rubix::Template.find(:id => id).should be_nil
  end

  it "should be able to import and export a template" do
    integration_test
    pending "Learning how to import/export XML via the API"
  end
  
end
