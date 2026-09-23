# frozen_string_literal: true

require_relative 'test_helper'

class CalendarTest < Minitest::Test
  def setup
    @calendar = ICU::Calendar.new('America/New_York', 'en-US')
  end

  def test_runtime_version_loading
    assert_match(/^\d+\.\d+\.\d+\.\d+$/, ICU.version)
    assert_match(/^(unversioned|major-suffixed \(\d+\))$/, ICU.symbol_version)
    assert_equal(ICU.version, @calendar.icu_version)
  end

  def test_get_and_set_millis
    date = 1_588_901_215_898.0
    @calendar.set_millis(date)
    assert_equal(date, @calendar.millis)
  end

  def test_set_date
    @calendar.set_millis(1_588_899_600_000.0) # 2020-05-07 21:00 in New York
    @calendar.set_date(2020, 4, 4) # ICU months are zero-based
    assert_equal(1_588_640_400_000.0, @calendar.millis)
  end

  def test_set_date_time_and_read_fields
    @calendar.set_millis(1_588_901_215_898.0)
    @calendar.set_date_time(2020, 4, 4, 21, 0, 0)

    assert_equal(1_588_640_400_898.0, @calendar.millis)
    assert_equal(4, @calendar.field('day'))
    assert_equal(898, @calendar.field('millisecond'))
  end

  def test_offsets_and_daylight_time
    @calendar.set_date_time(2020, 4, 7, 21, 0, 0)
    assert_equal(-5 * 60 * 60 * 1000, @calendar.zone_offset)
    assert_equal(60 * 60 * 1000, @calendar.dst_offset)
    assert_predicate(@calendar, :in_daylight_time?)

    @calendar.set_date_time(2020, 0, 15, 12, 0, 0)
    assert_equal(-5 * 60 * 60 * 1000, @calendar.zone_offset)
    assert_equal(0, @calendar.dst_offset)
    refute_predicate(@calendar, :in_daylight_time?)
  end

  def test_unknown_field
    error = assert_raises(ArgumentError) { @calendar.field('not_a_field') }
    assert_match(/unknown calendar field/, error.message)
  end
end
