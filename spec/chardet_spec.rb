# encoding: UTF-8

describe ICU::CharDet::Detector do

  let(:detector) { ICU::CharDet::Detector.new }

  it "should recognize UTF-8" do
    m = detector.detect("æåø")
    expect(m.name).to eq("UTF-8")
    expect(m.language).to be_a(String)
  end

  it "has a list of detectable charsets" do
    cs = detector.detectable_charsets
    expect(cs).to be_an(Array)
    expect(cs).to_not be_empty

    expect(cs.first).to be_a(String)
  end

  it "should disable / enable the input filter" do
    expect(detector.input_filter_enabled?).to be_falsey
    detector.input_filter_enabled = true
    expect(detector.input_filter_enabled?).to be_truthy
  end

  it "should should set declared encoding" do
    detector.declared_encoding = "UTF-8"
  end

  it "should detect several matching encodings" do
    expect(detector.detect_all("foo bar")).to be_an(Array)
  end

  it "should support null bytes" do
    # Create a utf-16 string and then force it to binary (ascii) to mimic data from net/http
    string = "foo".encode("UTF-16").force_encoding("binary")
    m = detector.detect(string)
    expect(m.name).to eq("UTF-16BE")
    expect(m.language).to be_a(String)
  end
end
