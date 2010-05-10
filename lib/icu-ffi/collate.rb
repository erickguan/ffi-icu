module ICU
  module Collate

    def collate(locale, arr)
      collator = new(locale)
      res = collator.colate(arr)
      collator.close
      
      res
    end

    
    class Collator
      
      def initialize(locale)
        
      end
    end

    
    
  end # Collate
end # ICU