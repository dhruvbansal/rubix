require 'spec_helper'

describe "HostGroups" do

  before do
    integration_test
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do
    
    it "returns nil on find" do
      Rubix::HostGroup.find(:name => 'rubix_spec_host_group_1').should be_nil
    end

    it "can be created" do
      hg = Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1')
      hg.save.should be_true
    end
    
  end

  describe "when existing" do

    before do
      @hg = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))
    end
    
    it "can be found" do
      Rubix::HostGroup.find(:name => 'rubix_spec_host_group_1').should_not be_nil
    end

    it "can have its name changed" do
      @hg.name = 'rubix_spec_host_group_2'
      @hg.save
      Rubix::HostGroup.find(:name => 'rubix_spec_host_group_1').should     be_nil
      Rubix::HostGroup.find(:name => 'rubix_spec_host_group_2').should_not be_nil
    end

    it "can be destroyed" do
      @hg.destroy
      Rubix::HostGroup.find(:name => 'rubix_spec_host_group_1').should be_nil
    end
  end
  
end
