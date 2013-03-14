require 'spec_helper'

describe "Graphs" do

  before do
    integration_test
    Rubix.logger = Logger.new STDOUT
    Rubix.logger.level = Logger::DEBUG
    @host_group = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))
    @host     = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@host_group], :interfaces => ['ip' => '123.123.123.123', 'main' => 1]))
    @host = Rubix::Host.find(:id => @host.id)
    @item = ensure_save(Rubix::Item.new(:key => 'rubix.spec1', :name => 'rubix item description 1', :host_id => @host.id, :interface_id => @host.interfaces.first.id, :value_type => :character, :units => 'B'))
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do
    it "returns nil on find" do
      Rubix::Graph.find(:name => 'graph_1').should be_nil
    end

    it "can be created" do
      graph = Rubix::Graph.new(:name => 'graph1', :height => 480, :width => 640, :graph_items => [:item_id => @item.id, :color => '000000'])
      graph.save.should be_true
      graph.id.should_not be_nil
      graph.id.should_not == 0
    end
  end

  describe "when existing" do

    before do
      @graph = ensure_save(Rubix::Graph.new(:name => 'graph_1', :height => 480, :width => 640, :graph_items => [:item_id => @item.id, :color => '000000']))
    end

    it "can be founded" do
      Rubix::Graph.find(:name => 'graph_1').should_not     be_nil
    end

    it "can be destroyed" do
      @graph.destroy
      Rubix::Graph.find(:name => 'graph_1').should be_nil
    end
  end
end

