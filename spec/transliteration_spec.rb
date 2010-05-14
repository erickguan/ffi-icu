# encoding: utf-8

require "spec_helper"

module ICU
  module Transliteration

    describe Transliterator do

      def transliterator(*args)
        @t = Transliterator.new(*args)
      end

     after { @t.close if @t }

      [
        { :id => "Any-Hex", :input => "abcde",  :output => "\\u0061\\u0062\\u0063\\u0064\\u0065"  },
        { :id => "Lower",   :input => "ABC",    :output => "abc"                                  }
      ].each do |test|

        it "should transliterate #{test[:id]}" do
          transliterator(test[:id]).transliterate(test[:input]).should == test[:output]
        end

      end

    end # Transliterator
  end # Transliteration
end # ICU
