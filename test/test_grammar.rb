require File.expand_path(File.dirname(__FILE__) + "/test_helper")

module RainbowCloth
  class TestGrammar < Test::Unit::TestCase
    Parent = Grammar.new do
      rule_for(:p) {|e| "<this is a paragraph>#{content_of(e)}</this is a paragraph>" }
    end

    WithPreProcessingRules = Grammar.new do
      include Parent

      pre_processing("p.foo") {|e| e.swap("<div>Cuack</div>") }
      rule_for(:div) {|e| "<this was a div>#{content_of(e)}</this was a div>" }
    end

    Child = Grammar.new do
      include Parent
    end

    OverWriter = Grammar.new do
      include WithPreProcessingRules

      rule_for(:div) {|e| content_of(e) }
    end

    def parse_with(grammar, html)
      grammar.process!(Hpricot(html))
    end

    context "extending a grammar" do
      test "the extended grammar should inherit the rules of the parent" do
        output = parse_with Child, "<p>Foo Bar</p>"
        assert_equal "<this is a paragraph>Foo Bar</this is a paragraph>", output
      end

      test "extending a grammar doesn't overwrite the parent's rules" do
        output = parse_with OverWriter, "<div>Foo</div>"
        assert_equal "Foo", output

        output = parse_with WithPreProcessingRules, "<div>Foo</div>"
        assert_equal "<this was a div>Foo</this was a div>", output
      end
    end

    context "pre processing rules" do
      test "mutate the DOM before parsing the tags" do
        output = parse_with WithPreProcessingRules, "<p class='foo'>Blah</p><p>O hai</p>"
        assert_equal "<this was a div>Cuack</this was a div><this is a paragraph>O hai</this is a paragraph>", output
      end
    end
  end
end
