# encoding: UTF-8

require 'spec_helper'

describe ICU::CharDet::Detector do
  before { @d = ICU::CharDet::Detector.new }
  after { @d.close }


  it "should recognize UTF-8" do
    @d.detect("æåø").name.should == "UTF-8"
  end

  it "has a list of detectable charsets" do
    cs = @d.detectable_charsets
    cs.should be_kind_of(Array)
    cs.should_not be_empty
    
    cs.first.should be_kind_of(String)
  end

end
