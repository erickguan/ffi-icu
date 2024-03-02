require 'test_helper'

class CollationTest < ActiveSupport::TestCase
  test "collates an array of strings" do
    assert_equal %w[æ ø å], ICU::Collation.collate("nb", %w[æ å ø])
  end
end
