require 'spec_helper'

describe "Triggers" do

  before do
    integration_test
    @host_group      = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))
    
    @template_1      = ensure_save(Rubix::Template.new(:name => 'rubix_spec_template_1', :host_groups => [@host_group]))
    @template_2      = ensure_save(Rubix::Template.new(:name => 'rubix_spec_template_2', :host_groups => [@host_group]))
    @template_item_1 = ensure_save(Rubix::Item.new(:key => 'rubix.spec1', :name => 'rubix template item description 1', :host_id => @template_1.id, :value_type => :character))
    @template_item_2 = ensure_save(Rubix::Item.new(:key => 'rubix.spec2', :name => 'rubix template item description 2', :host_id => @template_2.id, :value_type => :character))
    
    @host_1          = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@host_group], :interfaces => ['ip' => '123.123.123.123', 'main' => 1]))
    @host_1          = Rubix::Host.find(:id => @host_1.id) # reload for interfaces
    @host_2          = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_2', :host_groups => [@host_group], :interfaces => ['ip' => '123.123.123.123', 'main' => 1]))
    @host_2          = Rubix::Host.find(:id => @host_2.id) # reload for interfaces
    @host_item_1     = ensure_save(Rubix::Item.new(:key => 'rubix.spec1', :name => 'rubix host item description 1', :host_id => @host_1.id, :interface_id => @host_1.interfaces.first.id, :value_type => :character))
    @host_item_2     = ensure_save(Rubix::Item.new(:key => 'rubix.spec2', :name => 'rubix host item description 2', :host_id => @host_2.id, :interface_id => @host_2.interfaces.first.id, :value_type => :character))
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do

    it "returns nil on find" do
      Rubix::Trigger.find(:template_id => @template_1.id, :description => 'rubix template trigger description 1').should be_nil
      Rubix::Trigger.find(:host_id     => @host_1.id, :description => 'rubix host trigger description 1').should be_nil
    end

    it "can be created for a template" do
      trigger = Rubix::Trigger.new(:expression => '{rubix_spec_template_1:rubix.spec1.count(120,1)}>1', :description => 'rubix template trigger description 1', :status => :enabled)
      trigger.save.should be_true
      trigger.template.name.should == @template_1.name
    end

    it "can be created for a host" do
      trigger = Rubix::Trigger.new(:expression => '{rubix_spec_host_1:rubix.spec1.count(120,1)}>1', :description => 'rubix host trigger description 1', :status => :enabled)
      trigger.save.should be_true
      trigger.host.name.should == @host_1.name
    end
    
  end

  describe "when existing on a template" do

    before do
      @trigger = ensure_save(Rubix::Trigger.new(:expression => '{rubix_spec_template_1:rubix.spec1.count(120,1)}>1', :description => 'rubix template trigger description 1', :status => :enabled))
    end

    it "can have its host, description, priority, and status updated" do
      @trigger.status       = :disabled
      @trigger.priority     = :average
      @trigger.description  = 'rubix template trigger description 2'
      # @trigger.host_id      = @template_2.id
      @trigger.save.should be_true

      Rubix::Trigger.find(:description => 'rubix template trigger description 1', :host_id => @template_1.id).should be_nil

      new_trigger = Rubix::Trigger.find(:description => 'rubix template trigger description 2', :template_id => @template_1.id)
      new_trigger.should_not be_nil
      new_trigger.template.name.should == @template_1.name
      new_trigger.items.map(&:id).should include(@template_item_1.id)
      new_trigger.status.should == :disabled
      new_trigger.priority.should == :average
    end

    it "can be destroyed" do
      @trigger.destroy
      Rubix::Trigger.find(:description => 'rubix template trigger description 1', :template_id => @template_1.id).should be_nil
    end
  end

  describe "when existing on a host" do

    before do
      @trigger = ensure_save(Rubix::Trigger.new(:expression => '{rubix_spec_host_1:rubix.spec1.count(120,1)}>1', :description => 'rubix host trigger description 1', :status => :enabled))
    end

    it "can have its host, description, and status updated" do
      @trigger.status       = :disabled
      @trigger.description  = 'rubix host trigger description 2'
      # @trigger.host_id      = @host_2.id
      @trigger.save.should be_true

      Rubix::Trigger.find(:description => 'rubix host trigger description 1', :host_id => @host_1.id).should be_nil

      new_trigger = Rubix::Trigger.find(:description => 'rubix host trigger description 2', :host_id => @host_1.id)
      new_trigger.should_not be_nil
      new_trigger.host.name.should == @host_1.name
      new_trigger.items.map(&:id).should include(@host_item_1.id)
    end

    it "can be destroyed" do
      @trigger.destroy
      Rubix::Trigger.find(:description => 'rubix host trigger description 1', :host_id => @host_1.id).should be_nil
    end
  end
  
end
    
