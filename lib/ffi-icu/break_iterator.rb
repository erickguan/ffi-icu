# frozen_string_literal: true

module ICU
  class BreakIterator
    include Enumerable

    attr_reader :text

    DONE = -1

    def self.available_locales
      (0...Lib.ubrk_countAvailable).map do |idx|
        Lib.ubrk_getAvailable(idx)
      end
    end

    def initialize(type, locale)
      ptr = Lib.check_error { |err| Lib.ubrk_open(type, locale, nil, 0, err) }
      @iterator = FFI::AutoPointer.new(ptr, Lib.method(:ubrk_close))
    end

    def text=(str)
      text_pointer = UCharPointer.from_string(str)

      Lib.check_error do |err|
        Lib.ubrk_setText(@iterator, text_pointer, text_pointer.length_in_uchars, err)
      end

      @text = str
      @text_pointer = text_pointer
    end

    def each
      return to_enum(:each) unless block_given?

      # Positional methods expose ICU UTF-16 code-unit offsets.
      int = first

      while int != DONE
        yield(int)
        int = self.next
      end

      self
    end

    def each_substring
      return to_enum(:each_substring) unless block_given?

      chars = text.each_char.to_a
      utf16_to_ruby = ruby_offsets_for(chars)

      low = utf16_to_ruby[first]

      while (high = self.next) != DONE
        high = utf16_to_ruby[high]
        yield(chars[low...high].join)
        low = high
      end

      self
    end

    def ruby_offsets_for(chars)
      offsets = [0]
      utf16_offset = 0

      chars.each_with_index do |char, ruby_index|
        utf16_offset += char.ord > 0xFFFF ? 2 : 1
        offsets[utf16_offset] = ruby_index + 1
      end

      offsets
    end
    private :ruby_offsets_for

    def substrings
      each_substring.to_a
    end

    def next
      Lib.ubrk_next(@iterator)
    end

    def previous
      Lib.ubrk_previous(@iterator)
    end

    def first
      Lib.ubrk_first(@iterator)
    end

    def last
      Lib.ubrk_last(@iterator)
    end

    def preceding(offset)
      Lib.ubrk_preceding(@iterator, Integer(offset))
    end

    def following(offset)
      Lib.ubrk_following(@iterator, Integer(offset))
    end

    def current
      Lib.ubrk_current(@iterator)
    end

    def boundary?(offset)
      Lib.ubrk_isBoundary(@iterator, Integer(offset)) != 0
    end
  end
end
