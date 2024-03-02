require 'test_helper'

class CollatorTest < ActiveSupport::TestCase
  def setup
    @collator = ICU::Collation::Collator.new("nb")
  end

  test "collates an array of strings" do
    assert_equal %w[æ ø å], @collator.collate(%w[å ø æ])
  end

  test "raises an error if argument does not respond to :sort" do
    exception = assert_raises(ArgumentError) { @collator.collate(1) }
    assert_match(/ArgumentError expected but was/, exception.message)
  end

  test "returns available locales" do
    locales = ICU::Collation.available_locales
    assert locales.is_a?(Array)
    assert locales.include?("nb"), "Locale 'nb' should be included in the available locales."
  end

  test "returns the locale of the collator" do
    assert_equal 'nb', @collator.locale
  end

  test "compares two strings" do
    assert_equal 1, @collator.compare("blåbærsyltetøy", "blah")
    assert_equal 0, @collator.compare("blah", "blah")
    assert_equal(-1, @collator.compare("ba", "bl"))
  end

  test "knows if a string is greater than another" do
    assert @collator.greater("z", "a")
    assert !@collator.greater("a", "z")
  end

  test "knows if a string is greater or equal to another" do
    assert @collator.greater_or_equal("z", "a")
    assert @collator.greater_or_equal("z", "z")
    assert !@collator.greater_or_equal("a", "z")
  end

  test "knows if a string is equal to another" do
    assert @collator.equal("a", "a")
    assert !@collator.equal("a", "b")
  end

  test "returns rules" do
    assert @collator.rules.include?('ö<<<Ö'), "Rules should include 'ö<<<Ö'."
  end

  test "returns usable collation keys" do
    assert_operator @collator.collation_key("abc"), :<, @collator.collation_key("xyz")
  end

  test "can set and get normalization_mode with accessor method" do
    @collator.normalization_mode = true
    assert @collator.normalization_mode
  end

  test "can set and get normalization_mode with #[]" do
    @collator[:normalization_mode] = false
    assert !@collator.normalization_mode
  end

  test "can set and get case_first with accessor method" do
    @collator.case_first = :lower_first
    assert_equal :lower_first, @collator.case_first
  end

  test "can set and get strength with accessor method" do
    @collator.strength = :tertiary
    assert_equal :tertiary, @collator.strength
  end
end
