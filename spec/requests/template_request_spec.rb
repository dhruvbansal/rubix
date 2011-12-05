require 'spec_helper'

describe "Templates" do

  before do
    integration_test
    @host_group_1 = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))
    @host_group_2 = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_2'))
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do

    it "returns nil on find" do
      Rubix::Template.find(:name => 'rubix_spec_template_1').should be_nil
    end

    it "can be created" do
      template = Rubix::Template.new(:name => 'rubix_spec_template_1', :host_groups => [@host_group_1])
      template.save.should be_true
    end
    
  end

  describe "when existing" do

    before do
      @template = ensure_save(Rubix::Template.new(:name => 'rubix_spec_template_1', :host_groups => [@host_group_1]))
    end

    it "can have its name changed" do
      @template.name = 'rubix_spec_template_2'
      @template.save
      Rubix::Template.find(:name => 'rubix_spec_template_1').should     be_nil
      Rubix::Template.find(:name => 'rubix_spec_template_2').should_not be_nil
    end

    it "can be destroyed" do
      @template.destroy
      Rubix::Template.find(:name => 'rubix_spec_template_1').should be_nil
    end
    
  end

  it "should be able to import and export a template" do
    pending "Learning how to import/export XML via the API"
  end
  
end
