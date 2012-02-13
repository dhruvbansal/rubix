require 'spec_helper'

describe Rubix::ClusterMonitor do

  before do
    @wrapper = Class.new(Rubix::Monitor)
    @wrapper.class_eval do
      include Rubix::ClusterMonitor
      def hosts
        [
         Rubix::Host.new(:name => 'cluster1-facet1-host1'),
         Rubix::Host.new(:name => 'cluster1-facet1-host2'),
         Rubix::Host.new(:name => 'cluster1-facet2-host3'),
         
         Rubix::Host.new(:name => 'cluster2-facet1-host1'),
         Rubix::Host.new(:name => 'cluster2-facet1-host2'),
         Rubix::Host.new(:name => 'cluster2-facet2-host3'),

         Rubix::Host.new(:name => 'malformed')
        ]
      end
    end
  end

  it "should be able to filter hosts into clusters" do
    monitor = @wrapper.new(@wrapper.default_settings)
    monitor.clusters.should include('cluster1', 'cluster2', Rubix::ClusterMonitor::DEFAULT_CLUSTER)
    monitor.hosts_by_cluster['cluster1'].map(&:name).should include('cluster1-facet1-host1', 'cluster1-facet1-host2', 'cluster1-facet2-host3')
    monitor.hosts_by_cluster['cluster2'].map(&:name).should include('cluster2-facet1-host1', 'cluster2-facet1-host2', 'cluster2-facet2-host3')
    monitor.hosts_by_cluster[Rubix::ClusterMonitor::DEFAULT_CLUSTER].map(&:name).should include('malformed')
  end

  
  
end
  
