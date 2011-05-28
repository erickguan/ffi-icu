# encoding: utf-8

require "spec_helper"

module ICU
  describe BreakIterator do

    it "should return available locales" do
      locales = ICU::BreakIterator.available_locales
      locales.should be_kind_of(Array)
      locales.should_not be_empty
      locales.should include("en_US")
    end

    it "finds all word boundaries in an English string" do
      iterator = BreakIterator.new :word, "en_US"
      iterator.text = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
      iterator.to_a.should == [0, 5, 6, 11, 12, 17, 18, 21, 22, 26, 27, 28, 39, 40, 51, 52, 56, 57, 58, 61, 62, 64, 65, 72, 73, 79, 80, 90, 91, 93, 94, 100, 101, 103, 104, 110, 111, 116, 117, 123, 124]
    end

    it "finds all sentence boundaries in an English string" do
      iterator = BreakIterator.new :sentence, "en_US"
      iterator.text = "This is a sentence. This is another sentence, with a comma in it."
      iterator.to_a.should == [0, 20, 65]
    end

    it "can navigate back and forward" do
      iterator = BreakIterator.new :word, "en_US"
      iterator.text = "Lorem ipsum dolor sit amet."

      iterator.first.should == 0
      iterator.next
      iterator.current.should == 5
      iterator.last.should == 27
    end

    it "fetches info about given offset" do
      iterator = BreakIterator.new :word, "en_US"
      iterator.text = "Lorem ipsum dolor sit amet."

      iterator.following(3).should == 5
      iterator.preceding(6).should == 5

      iterator.should be_boundary(5)
      iterator.should_not be_boundary(10)
    end

    it "returns an Enumerator if no block was given" do
      iterator = BreakIterator.new :word, "nb"
      iterator.each.should be_kind_of(Enumerator)
    end

  end # BreakIterator
end # ICU
