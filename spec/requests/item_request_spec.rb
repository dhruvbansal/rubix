require 'spec_helper'

describe "Items" do

  before do
    integration_test
    @host_group = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))
    @host_1     = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@host_group], :interfaces => ['ip' => '123.123.123.123', 'main' => 1]))
    @host_1     = Rubix::Host.find(:id => @host_1.id) # reload interfaces with id
    @host_2     = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_2', :host_groups => [@host_group], :interfaces => ['ip' => '123.123.123.123', 'main' => 1]))
    @host_2     = Rubix::Host.find(:id => @host_2.id) # reload interfaces with id
    @app_1      = ensure_save(Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @host_1.id))
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do

    it "returns nil on find" do
      Rubix::Item.find(:key => 'rubix.spec1', :host_id => @host_1.id).should be_nil
    end

    it "can be created" do
      item = Rubix::Item.new(:key => 'rubix.spec1', :name => 'rubix item description 1', :host_id => @host_1.id, :interface_id => @host_1.interfaces.first.id, :value_type => :character, :applications => [@app_1], :units => 'B')
      item.save.should be_true
      item.host.name.should == @host_1.name
      item.applications.map(&:name).should include(@app_1.name)
    end
    
  end

  describe "when existing" do

    before do
      @item = ensure_save(Rubix::Item.new(:key => 'rubix.spec1', :name => 'rubix item description 1', :host_id => @host_1.id, :interface_id => @host_1.interfaces.first.id, :value_type => :character, :applications => [@app_1], :units => 'B'))
    end

    it "can have its host, application, and properties updated" do
      pending # now we can't change host without change interface first
      @item.key          = 'rubix.spec2'
      @item.name         = 'rubix item description 2'
      @item.type         = :external
      @item.value_type   = :unsigned_int
      @item.data_type    = :octal
      @item.history      = 91
      @item.trends       = 400
      @item.status       = :disabled
      @item.frequency    = 31
      @item.multiply_by  = 0.1
      @item.host_id      = @host_2.id
      @item.interface_id = @host_2.interfaces.first.id
      @item.units        = 'MB'
      @item.save.should be_true

      Rubix::Item.find(:key => 'rubix.spec1', :host_id => @host_1.id).should be_nil

      new_item = Rubix::Item.find(:key => 'rubix.spec2', :host_id => @host_2.id)
      new_item.should_not be_nil
      new_item.value_type.should == :unsigned_int
      new_item.data_type.should  == :octal
      new_item.history.should    == 91
      new_item.trends.should     == 400
      new_item.status.should     == :disabled
      new_item.type.should       == :external
      new_item.frequency.should  == 31
      new_item.multiply_by.should == 0.1
      new_item.host.name.should  == @host_2.name
      new_item.units.should      == 'MB'
    end

    it "can be destroyed" do
      @item.destroy
      Rubix::Item.find(:key => 'rubix.spec1', :host_id => @host_1.id).should be_nil
    end
  end
end
    
