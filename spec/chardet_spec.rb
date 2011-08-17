# encoding: UTF-8

require 'spec_helper'

describe ICU::CharDet::Detector do

  let(:detector) { ICU::CharDet::Detector.new }

  it "should recognize UTF-8" do
    m = detector.detect("æåø")
    m.name.should == "UTF-8"
    m.language.should be_kind_of(String)
  end

  it "has a list of detectable charsets" do
    cs = detector.detectable_charsets
    cs.should be_kind_of(Array)
    cs.should_not be_empty

    cs.first.should be_kind_of(String)
  end

  it "should disable / enable the input filter" do
    detector.input_filter_enabled?.should be_false
    detector.input_filter_enabled = true
    detector.input_filter_enabled?.should be_true
  end

  it "should should set declared encoding" do
    detector.declared_encoding = "UTF-8"
  end

  it "should detect several matching encodings" do
    detector.detect_all("foo bar").should be_instance_of(Array)
  end

end
