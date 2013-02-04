require 'spec_helper'

describe "Screens" do

  before do
    integration_test
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do
    it "returns nil on find" do
      Rubix::Screen.find(:name => 'screen_1').should be_nil
    end

    it "can be created" do
      screen = Rubix::Screen.new(:name => 'screen_1')
      screen.save.should be_true
      screen.id.should_not be_nil
      screen.id.should_not == 0
    end

  end

  describe "with screen items" do
    before do
      @host_group = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))
      @host     = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@host_group], :interfaces => ['ip' => '123.123.123.123', 'main' => 1]))
      @host = Rubix::Host.find(:id => @host.id)
      @item = ensure_save(Rubix::Item.new(:key => 'rubix.spec1', :name => 'rubix item description 1', :host_id => @host.id, :interface_id => @host.interfaces.first.id, :value_type => :character, :units => 'B'))
      @graph = ensure_save(Rubix::Graph.new(:name => 'graph1', :height => 480, :width => 640, :graph_items => [:item_id => @item.id, :color => '000000']))
    end

    it "can be created" do
      screen = Rubix::Screen.new(:name => 'screen_1', :screen_items => [:resource_id => @graph.id, :resource_type => :graph])
      screen.save.should be_true
      screen = Rubix::Screen.find(:id => screen.id)
      screen.screen_items.size.should == 1
    end
  end

  describe "when existing" do

    before do
      @screen = ensure_save(Rubix::Screen.new(:name => 'screen_2'))
    end

    it "can be founded" do
      Rubix::Screen.find(:name => 'screen_2').should_not     be_nil
    end

    it "can be destroyed" do
      @screen.destroy
      Rubix::Screen.find(:name => 'screen_2').should be_nil
    end
  end
end
