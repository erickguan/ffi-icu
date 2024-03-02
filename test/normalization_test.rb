require 'test_helper'

class NormalizationTest < ActiveSupport::TestCase
  test "normalizes a string - decomposed" do
    assert_equal [65, 778], ICU::Normalization.normalize("Å", :nfd).unpack("U*")
  end

  test "normalizes a string - composed" do
    assert_equal [197], ICU::Normalization.normalize("Å", :nfc).unpack("U*")
  end
end
