module ICU
  module Collation

    def self.collate(locale, arr)
      collator = Collator.new(locale)
      res = collator.collate(arr)
      collator.close

      res
    end

    def self.keywords
      enum_ptr = Lib.check_error { |error| Lib.ucol_getKeywords(error) }
      keywords = Lib.enum_ptr_to_array(enum_ptr)
      Lib.uenum_close enum_ptr

      hash = {}
      keywords.each do |keyword|
        enum_ptr = Lib.check_error { |error| Lib.ucol_getKeywordValues(keyword, error) }
        hash[keyword] = Lib.enum_ptr_to_array(enum_ptr)
        Lib.uenum_close(enum_ptr)
      end

      hash
    end

    def self.available_locales
      (0...Lib.ucol_countAvailable).map do |idx|
        Lib.ucol_getAvailable idx
      end
    end

    class Collator
      def initialize(locale)
        @c = Lib.check_error { |error| Lib.ucol_open(locale, error) }
      end

      def collate(array)
        array.sort do |a,b|
          Lib.ucol_strcoll(
            @c,
            UCharPointer.from_string(a), a.length,
            UCharPointer.from_string(b), b.length
          )
        end
      end

      def close
        Lib.ucol_close(@c)
      end


    end



  end # Collate
end # ICU
