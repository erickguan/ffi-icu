require 'test_helper'
require 'minitest/mock'

module ICU
  class LibSearchPathsTest < Minitest::Test
    def setup
      @search_paths_defined = Lib.instance_variable_defined?(:@search_paths)
      @original_paths = Lib.instance_variable_get(:@search_paths) if @search_paths_defined
      @original_icu_lib = ENV.delete('FFI_ICU_LIB')
      Lib.remove_instance_variable(:@search_paths) if @search_paths_defined
    end

    def teardown
      Lib.remove_instance_variable(:@search_paths) if Lib.instance_variable_defined?(:@search_paths)
      Lib.instance_variable_set(:@search_paths, @original_paths) if @search_paths_defined
      ENV['FFI_ICU_LIB'] = @original_icu_lib if @original_icu_lib
    end

    def test_prioritizes_the_native_debian_multiarch_directory
      paths = search_paths_with_multiarch(['/usr/lib/i386-linux-gnu', '/usr/lib/x86_64-linux-gnu'])

      assert_equal ['/usr/lib/x86_64-linux-gnu', '/usr/lib/i386-linux-gnu'], paths.last(2)
    end

    def test_keeps_the_existing_paths_as_fallbacks_when_no_native_multiarch_directory_is_available
      multiarch_paths = ['/usr/lib/aarch64-linux-gnu', '/usr/lib/i386-linux-gnu']

      assert_equal multiarch_paths, search_paths_with_multiarch(multiarch_paths).last(2)
    end

    private

    def search_paths_with_multiarch(multiarch_paths)
      with_constant(FFI::Platform, :IS_WINDOWS, false) do
        with_constant(FFI::Platform, :ARCH, 'x86_64') do
          stub = lambda do |pattern|
            assert_equal '/usr/lib/*-linux-gnu', pattern
            multiarch_paths.dup
          end

          Dir.stub(:[], stub) { Lib.search_paths }
        end
      end
    end

    def with_constant(mod, name, value)
      original = mod.const_get(name)
      mod.send(:remove_const, name)
      mod.const_set(name, value)
      yield
    ensure
      mod.send(:remove_const, name)
      mod.const_set(name, original)
    end
  end

  class LibCheckErrorTest < Minitest::Test
    def setup
      @return_value = Object.new
      @verbose = $VERBOSE
    end

    def teardown
      $VERBOSE = @verbose
    end

    def test_returns_the_block_result_upon_success
      assert_same(@return_value, Lib.check_error { |_status| @return_value })
      assert_same @return_value, (Lib.check_error do |status|
        status.write_int(0)
        @return_value
      end)
    end

    def test_raises_an_error_upon_failure
      error = assert_raises(ICU::Error) do
        Lib.check_error { |status| status.write_int(1) }
      end

      assert_match(/U_.*_ERROR/, error.message)
    end

    def test_prints_to_stderr_and_returns_the_block_result_when_warnings_are_enabled
      $VERBOSE = true
      result = nil
      _out, err = capture_io do
        result = Lib.check_error do |status|
          status.write_int(-127)
          @return_value
        end
      end

      assert_match(/U_.*_WARNING/, err)
      assert_same @return_value, result
    end

    def test_returns_the_block_result_without_printing_when_warnings_are_disabled
      $VERBOSE = false
      result = nil
      _out, err = capture_io do
        result = Lib.check_error do |status|
          status.write_int(-127)
          @return_value
        end
      end

      assert_empty err
      assert_same @return_value, result
    end
  end

  class LibVersionTest < Minitest::Test
    def test_cldr_version_is_a_version_info
      skip('Requires ICU >= 4.2') if Gem::Version.new(Lib.version.to_s) < Gem::Version.new('4.2')

      assert_kind_of Lib::VersionInfo, Lib.cldr_version
    end

    def test_cldr_version_is_populated
      skip('Requires ICU >= 4.2') if Gem::Version.new(Lib.version.to_s) < Gem::Version.new('4.2')

      refute_equal [0, 0, 0, 0], Lib.cldr_version.to_a
    end

    def test_icu_version_is_a_version_info
      assert_kind_of Lib::VersionInfo, Lib.version
    end

    def test_icu_version_is_populated
      refute_equal [0, 0, 0, 0], Lib.version.to_a
    end
  end

  class LibFindLibTest < Minitest::Test
    def setup
      @pattern = '{lib,}icuuc??.dll'
      @first_dir = File.expand_path('first')
      @second_dir = File.expand_path('second')
      @first_pattern = File.join(@first_dir, @pattern)
      @second_pattern = File.join(@second_dir, @pattern)
    end

    def test_stops_discovery_after_the_first_matching_directory
      library = File.join(@first_dir, 'icuuc78.dll')

      found, globbed = find_lib(@first_pattern => [library])

      assert_equal library, found
      assert_equal [@first_pattern], globbed
    end

    def test_returns_the_first_matching_file_within_the_first_matching_directory
      first_match = File.join(@first_dir, 'icuuc77.dll')
      second_match = File.join(@first_dir, 'icuuc78.dll')

      found, globbed = find_lib(@first_pattern => [first_match, second_match])

      assert_equal first_match, found
      assert_equal [@first_pattern], globbed
    end

    def test_continues_to_the_next_directory_when_no_library_matches
      library = File.join(@second_dir, 'icuuc78.dll')

      found, globbed = find_lib(@first_pattern => [], @second_pattern => [library])

      assert_equal library, found
      assert_equal [@first_pattern, @second_pattern], globbed
    end

    def test_returns_nil_when_no_directory_contains_a_matching_library
      found, = find_lib(@first_pattern => [], @second_pattern => [])

      assert_nil found
    end

    private

    # Returns the result of Lib.find_lib and the glob patterns it queried, in order.
    def find_lib(matches)
      globbed = []
      glob = lambda do |pattern|
        globbed << pattern
        matches.fetch(pattern)
      end

      found = Lib.stub(:search_paths, [@first_dir, @second_dir]) do
        Dir.stub(:glob, glob) { Lib.find_lib(@pattern) }
      end

      [found, globbed]
    end
  end
end
