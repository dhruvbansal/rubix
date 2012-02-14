require 'spec_helper'

describe "Scripts" do

  before do
    integration_test
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do
    
    it "returns nil on find" do
      Rubix::Script.find(:name => 'rubix_spec_script_1').should be_nil
    end

    it "can be created" do
      s = Rubix::Script.new(:name => 'rubix_spec_script_1', :command => 'foo')
      s.save.should be_true
    end
    
  end

  describe "when existing" do

    before do
      @s = ensure_save(Rubix::Script.new(:name => 'rubix_spec_script_1', :command => 'foo'))
    end
    
    it "can be found" do
      Rubix::Script.find(:name => 'rubix_spec_script_1').should_not be_nil
    end

    it "can have its properties changed" do
      @s.name    = 'rubix_spec_script_2'
      @s.command = 'bar'
      @s.access  = :write
      @s.save
      Rubix::Script.find(:name => 'rubix_spec_script_1').should be_nil
      new_s = Rubix::Script.find(:name => 'rubix_spec_script_2')
      new_s.should_not be_nil
      new_s.command.should == 'bar'
      new_s.access.should == :write
    end

    it "can be destroyed" do
      @s.destroy
      Rubix::Script.find(:name => 'rubix_spec_script_1').should be_nil
    end
  end
  
end
