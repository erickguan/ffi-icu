# encoding: UTF-8

require 'spec_helper'

module ICU
  describe Normalizer do
    describe 'NFD: nfc decompose' do
      let(:normalizer) { ICU::Normalizer.new(nil, 'nfc', :decompose) }

      it "should normalize a string" do
        normalizer.normalize("Å").unpack("U*").should == [65, 778]
        normalizer.normalize("ô").unpack("U*").should == [111, 770]
        normalizer.normalize("a").unpack("U*").should == [97]
        normalizer.normalize("中文").unpack("U*").should == [20013, 25991]
        normalizer.normalize("Äffin").unpack("U*").should == [65, 776, 102, 102, 105, 110]
        normalizer.normalize("Äﬃn").unpack("U*").should == [65, 776, 64259, 110]
        normalizer.normalize("Henry IV").unpack("U*").should == [72, 101, 110, 114, 121, 32, 73, 86]
        normalizer.normalize("Henry Ⅳ").unpack("U*").should == [72, 101, 110, 114, 121, 32, 8547]
      end
    end

    describe 'NFC: nfc compose' do
      let(:normalizer) { ICU::Normalizer.new(nil, 'nfc', :compose) }

      it "should normalize a string" do
        normalizer.normalize("Å").unpack("U*").should == [197]
        normalizer.normalize("ô").unpack("U*").should == [244]
        normalizer.normalize("a").unpack("U*").should == [97]
        normalizer.normalize("中文").unpack("U*").should == [20013, 25991]
        normalizer.normalize("Äffin").unpack("U*").should == [196, 102, 102, 105, 110]
        normalizer.normalize("Äﬃn").unpack("U*").should == [196, 64259, 110]
        normalizer.normalize("Henry IV").unpack("U*").should == [72, 101, 110, 114, 121, 32, 73, 86]
        normalizer.normalize("Henry Ⅳ").unpack("U*").should == [72, 101, 110, 114, 121, 32, 8547]
      end
    end

    describe 'NFKD: nfkc decompose' do
      let(:normalizer) { ICU::Normalizer.new(nil, 'nfkc', :decompose) }

      it "should normalize a string" do
        normalizer.normalize("Äffin").unpack("U*").should == [65, 776, 102, 102, 105, 110]
        normalizer.normalize("Äﬃn").unpack("U*").should == [65, 776, 102, 102, 105, 110]
        normalizer.normalize("Henry IV").unpack("U*").should == [72, 101, 110, 114, 121, 32, 73, 86]
        normalizer.normalize("Henry Ⅳ").unpack("U*").should == [72, 101, 110, 114, 121, 32, 73, 86]
      end
    end

    describe 'NFKC: nfkc compose' do
      let(:normalizer) { ICU::Normalizer.new(nil, 'nfkc', :compose) }

      it "should normalize a string" do
        normalizer.normalize("Äffin").unpack("U*").should == [196, 102, 102, 105, 110]
        normalizer.normalize("Äﬃn").unpack("U*").should == [196, 102, 102, 105, 110]
        normalizer.normalize("Henry IV").unpack("U*").should == [72, 101, 110, 114, 121, 32, 73, 86]
        normalizer.normalize("Henry Ⅳ").unpack("U*").should == [72, 101, 110, 114, 121, 32, 73, 86]
      end
    end
  end # Normalizer
end # ICU
