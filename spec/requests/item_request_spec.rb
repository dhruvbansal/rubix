require 'spec_helper'

describe "Items" do

  before do
    integration_test
    @host_group = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))
    @host_1     = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@host_group]))
    @host_2     = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_2', :host_groups => [@host_group]))
    @app_1      = ensure_save(Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @host_1.id))
    @app_2      = ensure_save(Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @host_2.id))
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do

    it "returns nil on find" do
      Rubix::Item.find(:key => 'rubix.spec1', :host_id => @host_1.id).should be_nil
    end

    it "can be created" do
      item = Rubix::Item.new(:key => 'rubix.spec1', :description => 'rubix item description 1', :host_id => @host_1.id, :value_type => :character, :applications => [@app_1])
      item.save.should be_true
      item.host.name.should == @host_1.name
      item.applications.map(&:name).should include(@app_1.name)
    end

  end

  describe "when existing" do

    before do
      @item = ensure_save(Rubix::Item.new(:key => 'rubix.spec1', :description => 'rubix item description 1', :host_id => @host_1.id, :value_type => :character, :applications => [@app_1]))
    end

    it "can have its host, application, and properties updated" do
      @item.key          = 'rubix.spec2'
      @item.description  = 'rubix item description 2'
      @item.type         = :external
      @item.value_type   = :unsigned_int
      @item.host_id      = @host_2.id
      @item.applications = [@app_2]
      @item.save.should be_true

      Rubix::Item.find(:key => 'rubix.spec1', :host_id => @host_1.id).should be_nil

      new_item = Rubix::Item.find(:key => 'rubix.spec2', :host_id => @host_2.id)
      new_item.should_not be_nil
      new_item.value_type.should == :unsigned_int
      new_item.type.should       == :external
      new_item.host.name.should == @host_2.name
      new_item.applications.map(&:name).should include(@app_2.name)
    end

    it "can be destroyed" do
      @item.destroy
      Rubix::Item.find(:key => 'rubix.spec1', :host_id => @host_1.id).should be_nil
    end
  end
end

