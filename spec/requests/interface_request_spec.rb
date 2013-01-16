require 'spec_helper'

describe "Interfaces" do

  before do
    integration_test
    @host_group = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))
    @host = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@host_group], :interfaces => [{ 'ip' => '123.123.123.123', 'main' => 1 }]))
  end

  after do
    truncate_all_tables
  end

  it "can modify an interface" do
    @host.interfaces = [{'ip' => '100.100.100.100', 'main' => 1}]
    @host.save

    h = Rubix::Host.find(:id => @host.id)
    h.interfaces.first.ip.should == '100.100.100.100'
  end
end
