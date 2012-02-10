require 'spec_helper'
require 'tempfile'

describe Rubix::Monitor do

  def monitor_wrapper(&block)
    Class.new(Rubix::Monitor).tap do |wrapper|
      wrapper.class_eval do
        define_method(:measure, &block)
      end
    end
  end

  before do
    @wrapper = monitor_wrapper do
      write ['key', 'value']
    end
    ::ARGV.replace([])
  end

  describe "making measurements" do

    it "should accept a two-element Array of [key, value]" do
      $stdout.should_receive(:puts).with('- key value')
      @wrapper.run
    end

    it "should accept a three-element Array of [host, key, value]" do
      @wrapper = monitor_wrapper do
        write ['host', 'key', 'value']
      end
      $stdout.should_receive(:puts).with('host key value')
      @wrapper.run
    end

    it "should accept a four-element Array of [host, key, timestamp, value]" do
      @wrapper = monitor_wrapper do
        write ['host', 'key', 1328875053, 'value']
      end
      $stdout.should_receive(:puts).with('host key 1328875053 value')
      @wrapper.run
    end

    it "should accept a hash with just a key and a value" do
      @wrapper = monitor_wrapper do
        write({ :key => 'key', :value => 'value' })
      end
      $stdout.should_receive(:puts).with('- key value')
      @wrapper.run
    end

    it "should accept a hash with a host, key, and a value" do
      @wrapper = monitor_wrapper do
        write({ :host => 'host', :key => 'key', :value => 'value' })
      end
      $stdout.should_receive(:puts).with('host key value')
      @wrapper.run
    end

    it "should accept a hash with a host, key, timestamp, and a value" do
      @wrapper = monitor_wrapper do
        write({ :host => 'host', :key => 'key', :timestamp => 1328875053, :value => 'value' })
      end
      $stdout.should_receive(:puts).with('host key 1328875053 value')
      @wrapper.run
    end

    it "should accept multiple values from a block" do
      @wrapper = monitor_wrapper do
        write do |data|
          data << ['key', 'value']
          data << { :key => 'key', :value => 'value' }
        end
        $stdout.should_receive(:puts).with("key value\nkey value")
        @wrapper.run
      end
      
    end
  end
  
  describe 'writing to STDOUT' do

    before do
      ::ARGV.replace([])
    end

    it "should be the default behavior when run with no arguments" do
      $stdout.should_receive(:puts).with('- key value')
      @wrapper.run
    end

    it "should flush after each write" do
      $stdout.stub!(:puts)
      $stdout.should_receive(:flush).twice()
      @wrapper.run
      @wrapper.run
    end
  end

  describe 'writing to files' do
    
    before do
      @file = Tempfile.new('monitor', '/tmp')
      ::ARGV.replace([@file.path])
    end

    after do
      FileUtils.rm(@file.path) if File.exist?(@file.path)
    end

    it "should create a new file if called with a path that doesn't exist" do
      FileUtils.rm(@file.path) if File.exist?(@file.path)
      @wrapper.run
      File.read(@file.path).should match('- key value')
    end

    it "should append to an existing file" do
      File.open(@file.path, 'w') { |f| f.puts('old content') }
      @wrapper.run
      File.read(@file.path).should include('- key value')
      File.read(@file.path).should include('old content')
    end
  end

  describe 'writing to FIFOs' do
    
    before do
      @file = Tempfile.new('monitor', '/tmp')
      FileUtils.rm(@file.path) if File.exist?(@file.path)
      `mkfifo #{@file.path}`
      ::ARGV.replace([@file.path])      
    end

    after do
      FileUtils.rm(@file.path) if File.exist?(@file.path)
    end

    it "should not block or error when writing to a FIFO with no listener" do
      @wrapper.run
    end

  end

  describe 'writing to a Sender' do
    before do
      @sender = mock("Rubix::Sender")
      @sender.stub!(:close) ; @sender.stub!(:flush)
      Rubix::Sender.should_receive(:new).with(kind_of(Hash)).and_return(@sender)
      ::ARGV.replace(['--send', '--host=foobar'])
    end

    it "should write to the sender" do
      @sender.should_receive(:puts).with('- key value')
      @wrapper.run
    end
  end
  
end
