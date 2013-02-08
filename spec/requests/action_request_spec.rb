require 'spec_helper'

describe "Actions" do

  before do
    integration_test
    Rubix.logger = Logger.new STDOUT
    Rubix.logger.level = Logger::DEBUG
    @user_group = Rubix::UserGroup.find_or_create(:name => 'rubix_spec_user_group_1')
    @user       = ensure_save(Rubix::User.new(:username => 'rubix_spec_user_1', :first_name => 'rubix', :last_name => 'user', :password => 'pass', :user_groups => [@user_group]))
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do

    it "returns nil on find" do
      Rubix::Action.find(:name => 'rubix_spec_action_1').should be_nil
    end

    it "can be created" do
      a = Rubix::Action.new(:name => 'rubix_spec_action_1', :operations => [{:user_groups => [@user_group]}])
      a.save.should be_true

      na = Rubix::Action.find(:name => 'rubix_spec_action_1')
      na.should_not be_nil
      na.name.should == 'rubix_spec_action_1'
      na.operations.size.should == 1
    end

    it "can be updated" do
      a = ensure_save(Rubix::Action.new(:name => 'rubix_spec_action_1', :operations => [{:user_groups => [@user_group]}]))

      na = Rubix::Action.find(:name => 'rubix_spec_action_1')
      na.save.should be_true
    end

  end

  describe "when existing" do
    before do
      @action = ensure_save(Rubix::Action.new(:name => 'rubix_spec_action_1', :operations => [{:user_groups => [@user_group]}]))
    end

    it "can be destroyed" do
      @action.destroy
      Rubix::Action.find(:name => 'rubix_spec_action_1').should be_nil
    end

  end
end
