require 'spec_helper'

describe Rubix::Sender do

  before do
    @config_file = Tempfile.new('sender', '/tmp')
  end

  describe "running in --fast mode" do

    it "should not attempt to make any calls to the Zabbix API when writing values" do
      Rubix.connection.should_not_receive(:request)
      @sender = Rubix::Sender.new(mock_settings('configuration_file' => @config_file.path, 'host' => 'foohost', 'server' => 'fooserver', 'fast' => true, 'sender' => 'echo'))
      @sender.process_line("foo.bar.baz	123\n")
      @sender.process_line({:host => 'newhost', :host_groups => 'foobar,baz', :data => [{:key => 'foo.bar.baz', :value => 123}]}.to_json)
    end
  end

  describe "running in auto-vivify mode" do
  end

end

