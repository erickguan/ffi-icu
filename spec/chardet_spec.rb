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
    detector.input_filter_enabled?.should be_falsey
    detector.input_filter_enabled = true
    detector.input_filter_enabled?.should be_truthy
  end

  it "should should set declared encoding" do
    detector.declared_encoding = "UTF-8"
  end

  it "should detect several matching encodings" do
    detector.detect_all("foo bar").should be_instance_of(Array)
  end

  it "should support null bytes" do
    # Create a utf-16 string and then force it to binary (ascii) to mimic data from net/http
    string = "foo".encode("UTF-16").force_encoding("binary")
    m = detector.detect(string)
    m.name.should == "UTF-16BE"
    m.language.should be_kind_of(String)
  end
end
