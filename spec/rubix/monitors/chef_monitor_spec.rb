require 'spec_helper'

describe Rubix::ChefMonitor do

  def mock_query query, nodes=[]
    require 'chef'
    chef_query = mock("Chef::Search::Query")
    ::Chef::Search::Query.should_receive(:new).and_return(chef_query)
    chef_query.should_receive(:search).with('node', query).and_return([nodes, nodes.length])
  end
  
  before do
    @wrapper = Class.new(Rubix::Monitor)
    @wrapper.send(:include, Rubix::ChefMonitor)
  end

  it "has options for talking to Chef" do
    @wrapper.default_settings.should include(:chef_server_url)
    @wrapper.default_settings.should include(:chef_node_name)
    @wrapper.default_settings.should include(:chef_client_key)
  end

  describe "finding nodes in Chef" do

    describe 'when a node exists' do
      before do
        @node = { 'node_name' => 'foobar', 'ipaddress' => '123', 'fdqn' => '456' }
      end

      it "can find it based on its node name" do
        mock_query('name:foobar', [@node])
        @wrapper.new(@wrapper.default_settings).chef_node_from_node_name('foobar').should == @node
      end

      it "can find it based on its IP" do
        mock_query('ipaddress:123 OR fqdn:123', [@node])
        @wrapper.new(@wrapper.default_settings).chef_node_from_ip('123').should == @node
      end

      it "can find it based on its FQDN" do
        mock_query('ipaddress:456 OR fqdn:456', [@node])
        @wrapper.new(@wrapper.default_settings).chef_node_from_ip('456').should == @node
      end
    end

    describe "when a node doesn't exist" do
      
      it "returns nil when searching by node name" do
        mock_query('name:foobar')
        @wrapper.new(@wrapper.default_settings).chef_node_from_node_name('foobar').should be_nil
      end

      it "returns nil when searching by IP" do
        mock_query('ipaddress:123 OR fqdn:123')
        @wrapper.new(@wrapper.default_settings).chef_node_from_ip('123').should be_nil
      end
    end
  end
end
  
