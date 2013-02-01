require 'spec_helper'

describe "Screens" do

  before do
    Rubix.logger = Logger.new STDOUT
    Rubix.logger.level = Logger::DEBUG
    integration_test
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do
    it "returns nil on find" do
      Rubix::Screen.find(:name => 'screen_1').should be_nil
    end

    it "can be created" do
      screen = Rubix::Screen.new(:name => 'screen_1')
      screen.save.should be_true
      screen.id.should_not be_nil
      screen.id.should_not == 0
    end
  end

  describe "when existing" do

    before do
      @screen = ensure_save(Rubix::Screen.new(:name => 'screen_2'))
    end

    it "can be founded" do
      Rubix::Screen.find(:name => 'screen_2').should_not     be_nil
    end

    it "can be destroyed" do
      @screen.destroy
      Rubix::Screen.find(:name => 'screen_2').should be_nil
    end
  end
end
