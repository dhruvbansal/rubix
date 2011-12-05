require 'spec_helper'

describe "Hosts" do

  before do
    integration_test
    @host_group_1 = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))

  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do

    it "returns nil on find" do
      Rubix::Host.find(:name => 'rubix_spec_host_1').should be_nil
    end

    it "can be created" do
      host = Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@host_group_1])
      host.save.should be_true
    end
  end

  describe "when existing" do
    before do
      @host_group_2 = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_2'))
      @host         = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_1',         :host_groups => [@host_group_1]))
      @template_1   = ensure_save(Rubix::Template.new(:name => 'rubix_spec_template_1', :host_groups => [@host_group_2]))
      @template_2   = ensure_save(Rubix::Template.new(:name => 'rubix_spec_template_2', :host_groups => [@host_group_2]))
    end

    it "can have its name changed" do
      @host.name = 'rubix_spec_host_2'
      @host.save

      Rubix::Host.find(:name => 'rubix_spec_host_1').should     be_nil
      Rubix::Host.find(:name => 'rubix_spec_host_2').should_not be_nil
    end

    it "can change its host groups" do
      @host.host_groups = [@host_group_1, @host_group_2]
      @host.save
      
      new_host = Rubix::Host.find(:name => 'rubix_spec_host_1')
      new_host.should_not be_nil
      new_host.host_groups.size.should == 2
      new_host.host_groups.map(&:name).should include('rubix_spec_host_group_1', 'rubix_spec_host_group_2')
    end

    it "can change its templates" do
      @host.templates = [@template_1, @template_2]
      @host.save
      
      new_host = Rubix::Host.find(:name => 'rubix_spec_host_1')
      new_host.should_not be_nil
      new_host.templates.size.should == 2
      new_host.templates.map(&:name).should include('rubix_spec_template_1', 'rubix_spec_template_2')
    end

    it "can be destroyed" do
      @host.destroy
      Rubix::Host.find(:name => 'rubix_spec_host_1').should be_nil
    end

  end
end
