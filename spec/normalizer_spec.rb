# encoding: UTF-8

module ICU
  describe Normalizer do
    describe 'NFD: nfc decompose' do
      let(:normalizer) { ICU::Normalizer.new(nil, 'nfc', :decompose) }

      it "should normalize a string" do
        expect(normalizer.normalize("Å").unpack("U*")).to eq([65, 778])
        expect(normalizer.normalize("ô").unpack("U*")).to eq([111, 770])
        expect(normalizer.normalize("a").unpack("U*")).to eq([97])
        expect(normalizer.normalize("中文").unpack("U*")).to eq([20013, 25991])
        expect(normalizer.normalize("Äffin").unpack("U*")).to eq([65, 776, 102, 102, 105, 110])
        expect(normalizer.normalize("Äﬃn").unpack("U*")).to eq([65, 776, 64259, 110])
        expect(normalizer.normalize("Henry IV").unpack("U*")).to eq([72, 101, 110, 114, 121, 32, 73, 86])
        expect(normalizer.normalize("Henry Ⅳ").unpack("U*")).to eq([72, 101, 110, 114, 121, 32, 8547])
      end
    end

    describe 'NFC: nfc compose' do
      let(:normalizer) { ICU::Normalizer.new(nil, 'nfc', :compose) }

      it "should normalize a string" do
        expect(normalizer.normalize("Å").unpack("U*")).to eq([197])
        expect(normalizer.normalize("ô").unpack("U*")).to eq([244])
        expect(normalizer.normalize("a").unpack("U*")).to eq([97])
        expect(normalizer.normalize("中文").unpack("U*")).to eq([20013, 25991])
        expect(normalizer.normalize("Äffin").unpack("U*")).to eq([196, 102, 102, 105, 110])
        expect(normalizer.normalize("Äﬃn").unpack("U*")).to eq([196, 64259, 110])
        expect(normalizer.normalize("Henry IV").unpack("U*")).to eq([72, 101, 110, 114, 121, 32, 73, 86])
        expect(normalizer.normalize("Henry Ⅳ").unpack("U*")).to eq([72, 101, 110, 114, 121, 32, 8547])
      end
    end

    describe 'NFKD: nfkc decompose' do
      let(:normalizer) { ICU::Normalizer.new(nil, 'nfkc', :decompose) }

      it "should normalize a string" do
        expect(normalizer.normalize("Äffin").unpack("U*")).to eq([65, 776, 102, 102, 105, 110])
        expect(normalizer.normalize("Äﬃn").unpack("U*")).to eq([65, 776, 102, 102, 105, 110])
        expect(normalizer.normalize("Henry IV").unpack("U*")).to eq([72, 101, 110, 114, 121, 32, 73, 86])
        expect(normalizer.normalize("Henry Ⅳ").unpack("U*")).to eq([72, 101, 110, 114, 121, 32, 73, 86])
      end
    end

    describe 'NFKC: nfkc compose' do
      let(:normalizer) { ICU::Normalizer.new(nil, 'nfkc', :compose) }

      it "should normalize a string" do
        expect(normalizer.normalize("Äffin").unpack("U*")).to eq([196, 102, 102, 105, 110])
        expect(normalizer.normalize("Äﬃn").unpack("U*")).to eq([196, 102, 102, 105, 110])
        expect(normalizer.normalize("Henry IV").unpack("U*")).to eq([72, 101, 110, 114, 121, 32, 73, 86])
        expect(normalizer.normalize("Henry Ⅳ").unpack("U*")).to eq([72, 101, 110, 114, 121, 32, 73, 86])
      end
    end
  end # Normalizer
end # ICU
