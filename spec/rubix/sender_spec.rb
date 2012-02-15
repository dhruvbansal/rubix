require 'spec_helper'

describe Rubix::Sender do

  before do
    @config_file = Tempfile.new('sender', '/tmp')
  end

  it "has sensible defaults" do
    sender = Rubix::Sender.new(:host => 'foobar')
    sender.server.should == 'localhost'
    sender.port.should   == 10051
    sender.config.should == '/etc/zabbix/zabbix_agentd.conf'
  end

  it "will raise an error without a host" do
    lambda { Rubix::Sender.new }.should raise_error(Rubix::Error)
  end

end
  
