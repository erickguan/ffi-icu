# encoding: UTF-8

require 'spec_helper'

describe ICUCharDet do
  it "should recognize UTF-8" do
    ICUCharDet.detect("æåø").name.should == "UTF-8"
  end
  
end
