# encoding: UTF-8

require 'spec_helper'

module ICU
  module Normalization
    describe "Normalization" do

      it "should normalize a string" do
        ICU::Normalization.normalize("æåø").should == "aeao"
      end


    end
  end # Normalization
end # ICU
