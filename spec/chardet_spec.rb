# encoding: UTF-8

require 'spec_helper'

describe ICU::CharDet::Detector do

  before { @d = ICU::CharDet::Detector.new }
  after { @d.close }

  it "should recognize UTF-8" do
    m = @d.detect("æåø")
    m.name.should == "UTF-8"
    m.language.should be_kind_of(String)
  end

  it "has a list of detectable charsets" do
    cs = @d.detectable_charsets
    cs.should be_kind_of(Array)
    cs.should_not be_empty

    cs.first.should be_kind_of(String)
  end

  it "should disable / enable the input filter" do
    @d.input_filter_enabled?.should be_false
    @d.input_filter_enabled = true
    @d.input_filter_enabled?.should be_true
  end

  it "should should set declared encoding" do
    @d.declared_encoding = "UTF-8"
  end

  it "should detect several matching encodings" do
    r = @d.detect_all("foo bar")
    r.should be_instance_of(Array)
  end

end
