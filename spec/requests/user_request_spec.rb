require 'spec_helper'

describe "Users" do

  before do
    integration_test
    @user_group = ensure_save(Rubix::UserGroup.new(:name => 'rubix_spec_user_group_1'))
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do
    
    it "returns nil on find" do
      Rubix::User.find(:username => 'rubix_spec_user_1', :first_name => 'rubix1', :last_name => 'user1').should be_nil
    end

    it "can be created" do
      hg = Rubix::User.new(:username => 'rubix_spec_user_1', :first_name => 'rubix1', :last_name => 'user1', :password => 'pass1', :user_groups => [@user_group])
      hg.save.should be_true
    end
    
  end

  describe "when existing" do

    before do
      @u = ensure_save(Rubix::User.new(:username => 'rubix_spec_user_1', :first_name => 'rubix1', :last_name => 'user1', :password => 'pass1', :user_groups => [@user_group]))
    end
    
    it "can be found" do
      Rubix::User.find(:username => 'rubix_spec_user_1').should_not be_nil
    end

    it "can have its name and settings changed" do
      @u.username   = 'rubix_spec_user_2'
      @u.first_name = 'rubix2'
      @u.last_name  = 'user2'
      @u.url        = 'http://foobar.com'
      @u.auto_login = true
      @u.type       = :super_admin
      @u.lang       = 'fo_ba'
      @u.theme      = 'foo.css'
      @u.refresh_period = 10
      @u.rows_per_page = 10
      @u.password   = 'pass2'
      @u.save
      Rubix::User.find(:username => 'rubix_spec_user_1').should be_nil
      nu = Rubix::User.find(:username => 'rubix_spec_user_2')
      nu.should_not be_nil
      nu.username.should           == 'rubix_spec_user_2'
      nu.first_name.should         == 'rubix2'
      nu.last_name.should          == 'user2'
      nu.url.should                == 'http://foobar.com'
      nu.auto_login.should         == true
      nu.type.should               == :super_admin
      nu.lang.should               == 'fo_ba'
      nu.theme.should              == 'foo.css'
      nu.refresh_period.should     == 10
      nu.rows_per_page.should      == 10
    end

    it "can be destroyed" do
      @u.destroy
      Rubix::User.find(:username => 'rubix_spec_user_1').should be_nil
    end
  end

  describe "handling media" do

    before do
      @media_type   = ensure_save(Rubix::MediaType.new(:name => 'rubix_spec_media_type_1'))
      @media_params = [{:media_type_id => @media_type.id, :address => "XXX"}]
    end

    it "can add media to a user when creating" do
      Rubix::User.new(:username => 'rubix_spec_user_1', :first_name => 'rubix1', :last_name => 'user1', :password => 'pass1', :media => @media_params, :user_groups => [@user_group]).save.should be_true
      # FIXME no facility to fetch media!!
    end

    
  end
end
