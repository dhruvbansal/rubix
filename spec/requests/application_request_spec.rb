require 'spec_helper'

describe "Applications" do

  before do
    integration_test
    @host_group = ensure_save(Rubix::HostGroup.new(:name => 'rubix_spec_host_group_1'))
    @host = ensure_save(Rubix::Host.new(:name => 'rubix_spec_host_1', :host_groups => [@host_group]))
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do

    it "returns nil on find" do
      Rubix::Application.find(:name => 'rubix_spec_app_1', :host_id => @host.id).should be_nil
    end

    it "can be created" do
      app = Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @host.id)
      app.save.should be_true
    end

  end

  describe "when existing" do

    before do
      @app = ensure_save(Rubix::Application.new(:name => 'rubix_spec_app_1', :host_id => @host.id))
    end

    it "can have its name changed" do
      @app.name = 'rubix_spec_app_2'
      @app.save
      Rubix::Application.find(:name => 'rubix_spec_app_1', :host_id => @host.id).should     be_nil
      Rubix::Application.find(:name => 'rubix_spec_app_2', :host_id => @host.id).should_not be_nil
    end

    it "can be destroyed" do
      @app.destroy
      Rubix::Application.find(:name => 'rubix_spec_app_1', :host_id => @host.id).should be_nil
    end

  end
end
