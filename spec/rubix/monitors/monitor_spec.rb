require 'spec_helper'
require 'tempfile'

describe Rubix::Monitor do

  before do
    @measurement = '{"data":[{"value":"bar","key":"foo"}]}'
    
    @wrapper = Class.new(Rubix::Monitor)
    @wrapper.class_eval do
      def measure
        write do |data|
          data << ['foo', 'bar']
        end
      end
    end
  end

  describe 'writing to STDOUT' do

    it "should be the default behavior when run with no arguments" do
      ::ARGV.replace([])
      $stdout.should_receive(:puts).with(@measurement)
      @wrapper.run
    end

    it "should flush after each write" do
      ::ARGV.replace([])
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
      File.read(@file.path).should include(@measurement)
    end

    it "should append to an existing file" do
      File.open(@file.path, 'w') { |f| f.puts('old content') }
      @wrapper.run
      File.read(@file.path).should include(@measurement)
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
  
end
  
