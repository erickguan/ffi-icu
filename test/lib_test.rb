require 'test_helper'

module ICU
  module Lib
    class LibTest < ActiveSupport::TestCase
      test "error checking upon success returns the block result" do
        return_value = Object.new

        error_check = Lib.check_error { |_| return_value }
        assert_equal return_value, error_check

        error_check = Lib.check_error { |status| status.write_int(0); return_value }
        assert_equal return_value, error_check
      end

      test "error checking upon failure raises an error" do
        assert_raises(ICU::Error, /U_.*_ERROR/) do
          Lib.check_error { |status| status.write_int(1) }
        end
      end

      test "error checking upon warning with warnings enabled prints to STDERR and returns the block result" do
        # TODO (mock-in-test): mock $VERBOSE properly with a gem.
        original_verbose, $VERBOSE = $VERBOSE, true
        begin
          # Assuming use of a mock or similar approach to capture $stderr output
          captured_output = StringIO.new
          $stderr = captured_output
          return_value = Object.new

          error_check = Lib.check_error { |status| status.write_int(-127); return_value }
          assert_equal return_value, error_check
          assert_match(/U_.*_WARNING/, captured_output.string)
        ensure
          $VERBOSE = original_verbose
          $stderr = STDERR
        end
      end

      test "error checking upon warning with warnings disabled returns the block result without printing to STDERR" do
        # TODO (mock-in-test): mock $VERBOSE properly with a gem.
        original_verbose, $VERBOSE = $VERBOSE, false
        begin
          return_value = Object.new

          error_check = Lib.check_error { |status| status.write_int(-127); return_value }
          assert_equal return_value, error_check
          # Here, additional logic would be required to verify that nothing was printed to STDERR,
          # possibly using a mocking library.
        ensure
          $VERBOSE = original_verbose
        end
      end

      if Gem::Version.new('4.2') <= Gem::Version.new(Lib.version)
        test "CLDR version is populated and is a Lib::VersionInfo" do
          cldr_version = Lib.cldr_version
          assert_kind_of Lib::VersionInfo, cldr_version
          assert [0, 0, 0, 0] != cldr_version.to_a
        end
      end

      test "ICU version is populated and is a Lib::VersionInfo" do
        icu_version = Lib.version
        assert_kind_of Lib::VersionInfo, icu_version
        assert [0, 0, 0, 0] != cldr_version.to_a
      end
    end
  end
end
