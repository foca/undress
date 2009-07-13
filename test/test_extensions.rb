require File.expand_path(File.dirname(__FILE__) + "/test_helper")

module RainbowCloth
  class Document
    def to_child_grammar_example
      Child.process!(doc)
    end
  end

  class Parent < Grammar
    rule_for(:p) {|e| "<this is a paragraph>#{content_of(e)}</this is a paragraph>" }
  end

  class Child < Parent; end

  class TextileTest < Test::Unit::TestCase
    context "extending a grammar" do
      test "the extended grammar should inherit the rules of the parent" do
        output = RainbowCloth.new("<p>Foo Bar</p>").to_child_grammar_example
        assert_equal "<this is a paragraph>Foo Bar</this is a paragraph>", output
      end
    end
  end
end
