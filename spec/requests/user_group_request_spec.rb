require 'spec_helper'

describe "UserGroups" do

  before do
    integration_test
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do
    
    it "returns nil on find" do
      Rubix::UserGroup.find(:name => 'rubix_spec_user_group_1').should be_nil
    end

    it "can be created" do
      ug = Rubix::UserGroup.new(:name => 'rubix_spec_user_group_1')
      ug.save.should be_true
    end
    
  end

  describe "when existing" do

    before do
      @ug = ensure_save(Rubix::UserGroup.new(:name => 'rubix_spec_user_group_1'))
    end
    
    it "can be found" do
      Rubix::UserGroup.find(:name => 'rubix_spec_user_group_1').should_not be_nil
    end

    it "can have its name and settings changed" do
      @ug.name       = 'rubix_spec_user_group_2'
      @ug.banned     = true
      @ug.api_access = true
      @ug.debug_mode = true
      @ug.gui_access = :disabled
      @ug.save
      Rubix::UserGroup.find(:name => 'rubix_spec_user_group_1').should     be_nil
      nug = Rubix::UserGroup.find(:name => 'rubix_spec_user_group_2')
      nug.should_not be_nil
      nug.name.should == 'rubix_spec_user_group_2'
      nug.banned.should == true
      nug.api_access.should == true
      nug.gui_access.should == :disabled
      nug.debug_mode.should == true
    end

    it "can be destroyed" do
      @ug.destroy
      Rubix::UserGroup.find(:name => 'rubix_spec_user_group_1').should be_nil
    end
  end

  describe "linking users to user groups" do

    before do
      @u1 = ensure_save(Rubix::User.new(:username => 'rubix_spec_user_1', :first_name => 'rubix1', :last_name => 'user1', :password => 'pass1'))
      @u2 = ensure_save(Rubix::User.new(:username => 'rubix_spec_user_2', :first_name => 'rubix2', :last_name => 'user2', :password => 'pass2'))
      @u3 = ensure_save(Rubix::User.new(:username => 'rubix_spec_user_3', :first_name => 'rubix3', :last_name => 'user3', :password => 'pass3'))
    end

    it "can add users on create" do
      ug = Rubix::UserGroup.new(:name => 'rubix_spec_user_group_1', :users => [@u1, @u2, @u3])
      ug.save
      nug = Rubix::UserGroup.find(:name => 'rubix_spec_user_group_1')
      nug.users.map(&:username).should include(*[@u1, @u2, @u3].map(&:username))
    end

    describe "with existing users" do

      before do
        Rubix::UserGroup.new(:name => 'rubix_spec_user_group_1', :users => [@u1, @u2]).save
        @ug = Rubix::UserGroup.find(:name => 'rubix_spec_user_group_1')
      end
      
      it "can will not mess with existing users if it doesn't need to" do
        @ug.name = 'rubix_spec_user_group_2'
        @ug.save
        nug = Rubix::UserGroup.find(:name => 'rubix_spec_user_group_2')
        nug.users.map(&:username).should include(*[@u1, @u2].map(&:username))
      end

      it "will replace users" do
        @ug.users = [@u2, @u3]
        @ug.save
        nug = Rubix::UserGroup.find(:name => 'rubix_spec_user_group_1')
        nug.users.map(&:username).should include(*[@u2, @u3].map(&:username))
      end

    end
  end
end
