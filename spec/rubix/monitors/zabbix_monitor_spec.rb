require 'spec_helper'

describe Rubix::ZabbixMonitor do

  before do
    @wrapper = Class.new(Rubix::Monitor)
    @wrapper.class_eval do
      include Rubix::ZabbixMonitor
    end
    @hosts = [Rubix::Host.new(:name => 'host1'), Rubix::Host.new(:name => 'host2'), Rubix::Host.new(:name => 'host3', :monitored => false)]
  end

  it "will raise an error when no template name or host group is defined" do
    lambda { @wrapper.new(@wrapper.default_settings).hosts }.should raise_error(Rubix::Error)
  end

  it "can find hosts based on a template" do
    @wrapper.class_eval do
      def template_name
        'Template_Foo'
      end
    end
    @template = Rubix::Template.new(:name => 'Template_Foo')
    Rubix::Template.should_receive(:find).with(:name => 'Template_Foo').and_return(@template)
    @template.should_receive(:host_ids).and_return([1,2,3])
    Rubix::Host.should_receive(:list).with([1,2,3]).and_return(@hosts)
    @wrapper.new(@wrapper.default_settings).hosts.should == @hosts[0..1]
  end

  it "can find hosts based on a host group" do
    @wrapper.class_eval do
      def host_group_name
        'Foos'
      end
    end
    @host_group = Rubix::HostGroup.new(:name => 'Foos')
    Rubix::HostGroup.should_receive(:find).with(:name => 'Foos').and_return(@host_group)
    @host_group.should_receive(:host_ids).and_return([1,2,3])
    Rubix::Host.should_receive(:list).with([1,2,3]).and_return(@hosts)
    @wrapper.new(@wrapper.default_settings).hosts.should == @hosts[0..1]
  end
  
end

  

