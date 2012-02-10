require 'spec_helper'

describe Rubix::ClusterMonitor do

  def mock_chef_query nodes
    query = mock("Chef::Search::Query")
    require 'chef'
    ::Chef::Search::Query.should_receive(:new).and_return(query)
    query.should_receive(:search).and_return([nodes, nodes.size])
  end
  
  it "should correctly carve up a group of nodes into clusters" do
    mock_chef_query([
                     { 'cluster_name' => 'foo', 'state' => 'started', 'ipaddress' => '123' },
                     { 'cluster_name' => 'foo', 'state' => 'stopped', 'ipaddress' => '456' },
                     { 'cluster_name' => 'bar', 'state' => 'started', 'ipaddress' => '789' },
                     { 'cluster_name' => 'bar', 'state' => 'stopped', 'ipaddress' => '321' }
                    ])
    cm = Rubix::ClusterMonitor.new({})
    cm.clusters.should include('foo', 'bar')
    cm.private_ips_by_cluster.should == { 'foo' => ['123'], 'bar' => ['789'] }
    cm.all_private_ips_by_cluster.should == { 'foo' => ['123', '456'], 'bar' => ['789', '321'] }

    cm.nodes_by_cluster['foo'].size.should == 1
    cm.nodes_by_cluster['bar'].size.should == 1

    cm.all_nodes_by_cluster['foo'].size.should == 2
    cm.all_nodes_by_cluster['bar'].size.should == 2
    
  end
  
  
end
  
