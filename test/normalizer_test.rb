require 'test_helper'

class NormalizerTest < ActiveSupport::TestCase
  test "NFD: nfc decompose normalizes a string" do
    normalizer = ICU::Normalizer.new(nil, 'nfc', :decompose)
    assert_equal [65, 778], normalizer.normalize("Å").unpack("U*")
    assert_equal [111, 770], normalizer.normalize("ô").unpack("U*")
    assert_equal [97], normalizer.normalize("a").unpack("U*")
    assert_equal [20013, 25991], normalizer.normalize("中文").unpack("U*")
    assert_equal [65, 776, 102, 102, 105, 110], normalizer.normalize("Äffin").unpack("U*")
    assert_equal [65, 776, 64259, 110], normalizer.normalize("Äﬃn").unpack("U*")
    assert_equal [72, 101, 110, 114, 121, 32, 73, 86], normalizer.normalize("Henry IV").unpack("U*")
    assert_equal [72, 101, 110, 114, 121, 32, 8547], normalizer.normalize("Henry Ⅳ").unpack("U*")
  end

  test "NFC: nfc compose normalizes a string" do
    normalizer = ICU::Normalizer.new(nil, 'nfc', :compose)
    assert_equal [197], normalizer.normalize("Å").unpack("U*")
    assert_equal [244], normalizer.normalize("ô").unpack("U*")
    assert_equal [97], normalizer.normalize("a").unpack("U*")
    assert_equal [20013, 25991], normalizer.normalize("中文").unpack("U*")
    assert_equal [196, 102, 102, 105, 110], normalizer.normalize("Äffin").unpack("U*")
    assert_equal [196, 64259, 110], normalizer.normalize("Äﬃn").unpack("U*")
    assert_equal [72, 101, 110, 114, 121, 32, 73, 86], normalizer.normalize("Henry IV").unpack("U*")
    assert_equal [72, 101, 110, 114, 121, 32, 8547], normalizer.normalize("Henry Ⅳ").unpack("U*")
  end

  test "NFKD: nfkc decompose normalizes a string" do
    normalizer = ICU::Normalizer.new(nil, 'nfkc', :decompose)
    assert_equal [65, 776, 102, 102, 105, 110], normalizer.normalize("Äffin").unpack("U*")
    assert_equal [65, 776, 102, 102, 105, 110], normalizer.normalize("Äﬃn").unpack("U*")
    assert_equal [72, 101, 110, 114, 121, 32, 73, 86], normalizer.normalize("Henry IV").unpack("U*")
    assert_equal [72, 101, 110, 114, 121, 32, 73, 86], normalizer.normalize("Henry Ⅳ").unpack("U*")
  end

  test "NFKC: nfkc compose normalizes a string" do
    normalizer = ICU::Normalizer.new(nil, 'nfkc', :compose)
    assert_equal [196, 102, 102, 105, 110], normalizer.normalize("Äffin").unpack("U*")
    assert_equal [196, 102, 102, 105, 110], normalizer.normalize("Äﬃn").unpack("U*")
    assert_equal [72, 101, 110, 114, 121, 32, 73, 86], normalizer.normalize("Henry IV").unpack("U*")
    assert_equal [72, 101, 110, 114, 121, 32, 73, 86], normalizer.normalize("Henry Ⅳ").unpack("U*")
  end
end
