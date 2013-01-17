require 'spec_helper'

describe "User Macros" do

  before do
    integration_test
    @host_group = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))
    @host       = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@host_group], :interfaces => ['ip' => '123.123.123.123', 'main' => 1]))
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do

    it "returns nil on find" do
      Rubix::UserMacro.find(:name => 'rubix_spec_macro_1', :host_id => @host.id).should be_nil
    end

    it "can be created" do
      um = Rubix::UserMacro.new(:name => 'rubix_spec_macro_1', :value => 'rubix_spec_value_1', :host_id => @host.id)
      um.save.should be_true
    end

  end

  describe "when existing" do

    before do
      @macro = ensure_save(Rubix::UserMacro.new(:name => 'rubix_spec_macro_1', :value => 'rubix_spec_value_1', :host_id => @host.id))
    end

    it "can have its value changed" do
      @macro.value = 'rubix_spec_value_2'
      @macro.save

      new_macro = Rubix::UserMacro.find(:name => 'rubix_spec_macro_1', :host_id => @host.id)
      new_macro.should_not be_nil
      new_macro.value.should == 'rubix_spec_value_2'
    end

    it "can be destroyed" do
      @macro.destroy
      Rubix::UserMacro.find(:name => 'rubix_spec_macro_1', :host_id => @host.id).should be_nil
    end
  end
end
