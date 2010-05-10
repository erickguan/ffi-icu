module ICU
  module Collate

    def self.collate(locale, arr)
      collator = new(locale)
      res = collator.collate(arr)
      collator.close
      
      res
    end
    
    def self.available_locales
      enum_ptr = Lib.check_error { |err| Lib.ucol_openAvailableLocales(err) }
      res = Lib.enum_ptr_to_array(enum_ptr)
      Lib.enum_close(enum_ptr)
      
      res
    end

    class Collator
      def initialize(locale)
        @c = Lib.check_error { |error| Lib.ucol_open(locale, error) }
      end
      
      def collate(array)
        array.sort { |a,b| r=Lib.ucol_strcoll(@c, a, a.bytesize, b, b.bytesize); p [a,b,r]; r }
      end
      
      def close
        Libu.ucol_close(@c)
      end
      
      
    end

    
    
  end # Collate
end # ICU