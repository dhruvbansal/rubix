require 'spec_helper'

describe "CRUD for templates" do

  before do
    @hg = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    @hg.save
  end

  after do
    @hg.destroy
  end

  it "should be able to create, update, and destroy a template" do
    integration_test
    
    Rubix::Template.find(:name => 'rubix_spec_template_1').should be_nil
    
    t = Rubix::Template.new(:name => 'rubix_spec_template_1', :host_groups => [@t])
    t.save
    Rubix::Template.find(:name => 'rubix_spec_template_1').should_not be_nil
    id = t.id
    id.should_not be_nil

    t.name = 'rubix_spec_template_2'
    t.update

    Rubix::Template.find(:id => id).name.should == 'rubix_spec_template_2'
    
    t.destroy
    Rubix::Template.find(:id => id).should be_nil
  end
end
