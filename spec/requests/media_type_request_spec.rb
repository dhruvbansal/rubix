require 'spec_helper'

describe "MediaTypes" do

  before do
    integration_test
  end

  after do
    truncate_all_tables
  end

  describe "when not existing" do
    
    it "returns nil on find" do
      Rubix::MediaType.find(:name => 'rubix_spec_media_type_1').should be_nil
    end

    it "can be created" do
      mt = Rubix::MediaType.new(:name => 'rubix_spec_media_type_1', :path => 'foo')
      mt.save.should be_true
    end
    
  end

  describe "when existing" do

    before do
      @mt = ensure_save(Rubix::MediaType.new(:name => 'rubix_spec_media_type_1', :path => 'foo'))
    end
    
    it "can be found" do
      Rubix::MediaType.find(:name => 'rubix_spec_media_type_1').should_not be_nil
    end

    it "can have its properties changed" do
      @mt.name = 'rubix_spec_media_type_2'
      @mt.type        = :sms
      @mt.modem       = '/foo/bar'
      @mt.save
      Rubix::MediaType.find(:name => 'rubix_spec_media_type_1').should be_nil
      new_mt = Rubix::MediaType.find(:name => 'rubix_spec_media_type_2')
      new_mt.should_not be_nil
      new_mt.type.should == :sms
      new_mt.modem.should == '/foo/bar'
    end

    it "can be destroyed" do
      @mt.destroy
      Rubix::MediaType.find(:name => 'rubix_spec_media_type_1').should be_nil
    end
  end
  
end
