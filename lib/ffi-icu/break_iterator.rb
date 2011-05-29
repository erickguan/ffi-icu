module ICU
  class BreakIterator
    include Enumerable

    UBRK_DONE = -1

    def self.available_locales
      (0...Lib.ubrk_countAvailable).map do |idx|
        Lib.ubrk_getAvailable idx
      end
    end

    def initialize(type, locale)
      ptr = Lib.check_error { |err| Lib.ubrk_open(type, locale, nil, 0, err) }

      @iterator = FFI::AutoPointer.new(ptr, Lib.method(:ubrk_close))
    end

    def text=(str)
      Lib.check_error { |err|
        Lib.ubrk_setText @iterator, UCharPointer.from_string(str), str.jlength, err
      }
    end

    def each(&blk)
      return to_enum(:each) unless block_given?

      int = first

      while int != UBRK_DONE
        yield int
        int = self.next
      end
    end

    def next
      Lib.ubrk_next @iterator
    end

    def previous
      Lib.ubrk_next @iterator
    end

    def first
      Lib.ubrk_first @iterator
    end

    def last
      Lib.ubrk_last @iterator
    end

    def preceding(offset)
      Lib.ubrk_preceding @iterator, Integer(offset)
    end

    def following(offset)
      Lib.ubrk_following @iterator, Integer(offset)
    end

    def current
      Lib.ubrk_current @iterator
    end

    def boundary?(offset)
      Lib.ubrk_isBoundary(@iterator, Integer(offset)) != 0
    end

  end # BreakIterator
end # ICU