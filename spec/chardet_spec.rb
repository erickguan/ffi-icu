describe ICU::CharDet::Detector do
  let(:detector) { described_class.new }

  it 'recognizes UTF-8' do
    m = detector.detect('æåø')
    expect(m.name).to(eq('UTF-8'))
    expect(m.language).to(be_a(String))
  end

  it 'has a list of detectable charsets' do
    cs = detector.detectable_charsets
    expect(cs).to(be_an(Array))
    expect(cs).not_to(be_empty)

    expect(cs.first).to(be_a(String))
  end

  it 'disables / enable the input filter' do
    expect(detector).not_to(be_input_filter_enabled)
    detector.input_filter_enabled = true
    expect(detector).to(be_input_filter_enabled)
  end

  it 'shoulds set declared encoding' do
    detector.declared_encoding = 'UTF-8'
  end

  it 'detects several matching encodings' do
    expect(detector.detect_all('foo bar')).to(be_an(Array))
  end

  it 'supports null bytes' do
    # Create a utf-16 string and then force it to binary (ascii) to mimic data from net/http
    string = 'foo'.encode('UTF-16').force_encoding('binary')
    m = detector.detect(string)
    expect(m.name).to(eq('UTF-16BE'))
    expect(m.language).to(be_a(String))
  end
end
