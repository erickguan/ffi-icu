# encoding: UTF-8

module ICU
  module Normalization
    #  http://bugs.icu-project.org/trac/browser/icu/trunk/source/test/cintltst/cnormtst.c

    describe "Normalization" do

      it "should normalize a string - decomposed" do
        expect(ICU::Normalization.normalize("Å", :nfd).unpack("U*")).to eq([65, 778])
      end

      it "should normalize a string - composed" do
        expect(ICU::Normalization.normalize("Å", :nfc).unpack("U*")).to eq([197])
      end

      # TODO: add more normalization tests


    end
  end # Normalization
end # ICU
