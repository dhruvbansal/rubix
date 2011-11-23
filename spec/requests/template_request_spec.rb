require 'spec_helper'

describe "CRUD for templates" do

  before do
    @hg1 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
    ensure_save(@hg1)

    @hg2 = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_2')
    ensure_save(@hg2)
  end

  after do
    ensure_destroy(@hg1, @hg2)
  end

  it "should be able to create, update, and destroy a template" do
    integration_test
    
    Rubix::Template.find(:name => 'rubix_spec_template_1').should be_nil
    
    t1 = Rubix::Template.new(:name => 'rubix_spec_template_1', :host_groups => [@hg1])
    t1.save.should be_true
    id = t1.id
    id.should_not be_nil

    ensure_destroy(t1) do
      t2 = Rubix::Template.find(:name => 'rubix_spec_template_1')
      t2.should_not be_nil
      t2.id.should == id
      t2.host_group_ids.should include(@hg1.id)
      
      t1.name = 'rubix_spec_template_2'
      t1.host_groups = [@hg2]
      t1.save.should be_true

      t2 = Rubix::Template.find(:id => id)
      t2.name.should == 'rubix_spec_template_2'
      t2.host_group_ids.should_not include(@hg1.id)
      t2.host_group_ids.should     include(@hg2.id)
      
      t1.destroy
      Rubix::Template.find(:id => id).should be_nil
    end
  end

  it "should be able to import and export a template" do
    integration_test
    pending "Learning how to import/export XML via the API"
  end
  
end
