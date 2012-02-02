require 'spec_helper'

describe "TimeSeries" do

  before do
    integration_test
    @host_group = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))
    @host       = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@host_group]))
  end

  after do
    truncate_all_tables
  end

  describe "setting a timeframe" do

    it "should set a default timeframe" do
      Rubix::TimeSeries.new.from.should_not be_nil
      Rubix::TimeSeries.new.upto.should_not be_nil
    end

    it "should accept a given timeframe when querying" do
      Rubix::TimeSeries.find_params(:item_id => 100, :from => '1327543430', :upto => Time.at(1327543450))[:time_from].should == '1327543430'
      Rubix::TimeSeries.find_params(:item_id => 100, :from => '1327543430', :upto => Time.at(1327543450))[:time_till].should == '1327543450'
    end
  end
  

  describe "when the item doesn't exist" do

    it "returns an empty TimeSeries" do
      @ts = Rubix::TimeSeries.find(:item_id => 100)
      @ts.should_not be_nil
      @ts.raw_data.should be_empty
      @ts.parsed_data.should be_empty
    end

  end

  describe "when the item exists" do

    before do
      @item = ensure_save(Rubix::Item.new(:host_id => @host.id, :key => 'foo.bar.baz', :value_type => :unsigned_int, :description => "rubix item description"))
    end

    it "should parse the results properly" do
      @ts = Rubix::TimeSeries.find(:item_id => @item.id)
      @ts.should_not be_nil
      @ts.should_receive(:raw_data).and_return([{'clock' => '1327543429', 'value' => '3'}, {'clock' => '1327543430'}])
      @ts.parsed_data.should == [{'time' => Time.at(1327543429), 'value' => 3}]
    end

  end
end
    
