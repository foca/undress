require File.expand_path(File.dirname(__FILE__) + "/test_helper")

module RainbowCloth
  class TestGrammar < Test::Unit::TestCase
    setup do
      @parent = Grammar.new do
        rule_for(:p) {|e| "<this is a paragraph>#{content_of(e)}</this is a paragraph>" }
      end

      @with_pre_processing_rules = Grammar.new(@parent) do
        pre_processing("p.foo") {|e| e.swap("<div>Cuack</div>") }
        rule_for(:div) {|e| "<this was a div>#{content_of(e)}</this was a div>" }
      end

      @child = Grammar.new(@parent)

      @overwriter = Grammar.new(@with_pre_processing_rules) do
        rule_for(:div) {|e| content_of(e) }
      end
    end

    def parse_with(grammar, html)
      grammar.process!(Hpricot(html))
    end

    context "extending a grammar" do
      test "the extended grammar should inherit the rules of the parent" do
        output = parse_with @child, "<p>Foo Bar</p>"
        assert_equal "<this is a paragraph>Foo Bar</this is a paragraph>", output
      end

      test "extending a grammar doesn't overwrite the parent's rules" do
        output = parse_with @overwriter, "<div>Foo</div>"
        assert_equal "Foo", output

        output = parse_with @with_pre_processing_rules, "<div>Foo</div>"
        assert_equal "<this was a div>Foo</this was a div>", output
      end
    end

    context "pre processing rules" do
      test "mutate the DOM before parsing the tags" do
        output = parse_with @with_pre_processing_rules, "<p class='foo'>Blah</p><p>O hai</p>"
        assert_equal "<this was a div>Cuack</this was a div><this is a paragraph>O hai</this is a paragraph>", output
      end
    end
  end
end
