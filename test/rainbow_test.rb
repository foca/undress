require "test/unit"
require "contest"
require "ruby-debug"
require File.expand_path(File.dirname(__FILE__) + "/../lib/rainbow")

class RainbowTest < Test::Unit::TestCase
  def assert_renders_textile(textile, html)
    assert_equal textile, Rainbow::HTML.new(html).to_textile
  end

  context "Converting HTML" do
    test "converts nested tags" do
      assert_renders_textile "\n\nh2. _this is *very* important_\n\n", "<h2><em>this is <strong>very</strong> important</em></h2>"
    end

    context "inline elements" do
      test "converts <strong> tags" do
        assert_renders_textile "*foo bar*", "<strong>foo bar</strong>"
      end

      test "converts <em> tags" do
        assert_renders_textile "_foo bar_", "<em>foo bar</em>"
      end

      test "converts <code> tags" do
        assert_renders_textile "@foo bar@", "<code>foo bar</code>"
      end

      test "converts <cite> tags" do
        assert_renders_textile "??foo bar??", "<cite>foo bar</cite>"
      end
    end

    context "links" do
      test "converts simple links (without title)" do
        assert_renders_textile "[Foo Bar:/cuack]", "<a href='/cuack'>Foo Bar</a>"
      end

      test "converts links with titles" do
        assert_renders_textile "[Foo Bar (You should see this):/cuack]", "<a href='/cuack' title='You should see this'>Foo Bar</a>"
      end
    end

    context "images" do
      test "converts images without alt attributes" do
        assert_renders_textile "!http://example.com/image.png!", "<img src='http://example.com/image.png'/>"
      end

      test "converts images with alt attributes" do
        assert_renders_textile "!http://example.com/image.png(Awesome Pic)!", "<img src='http://example.com/image.png' alt='Awesome Pic'/>"
      end
    end

    context "headers" do
      test "converts <h1> tags" do
        assert_renders_textile "\n\nh1. foo bar\n\n", "<h1>foo bar</h1>"
      end

      test "converts <h2> tags" do
        assert_renders_textile "\n\nh2. foo bar\n\n", "<h2>foo bar</h2>"
      end

      test "converts <h3> tags" do
        assert_renders_textile "\n\nh3. foo bar\n\n", "<h3>foo bar</h3>"
      end

      test "converts <h4> tags" do
        assert_renders_textile "\n\nh4. foo bar\n\n", "<h4>foo bar</h4>"
      end

      test "converts <h5> tags" do
        assert_renders_textile "\n\nh5. foo bar\n\n", "<h5>foo bar</h5>"
      end

      test "converts <h6> tags" do
        assert_renders_textile "\n\nh6. foo bar\n\n", "<h6>foo bar</h6>"
      end
    end

    context "lists" do
      test "converts bullet lists" do
        assert_renders_textile "\n\n* foo\n* bar\n\n", "<ul><li>foo</li><li>bar</li></ul>"
      end

      test "converts numbered lists" do
        assert_renders_textile "\n\n# foo\n# bar\n\n", "<ol><li>foo</li><li>bar</li></ol>"
      end

      test "converts nested bullet lists" do
        assert_renders_textile "\n\n* foo\n** bar\n* baz\n\n", "<ul><li>foo<ul><li>bar</li></ul></li><li>baz</li></ul>"
      end

      test "converts nested numbered lists" do
        assert_renders_textile "\n\n# foo\n## bar\n# baz\n\n", "<ol><li>foo<ol><li>bar</li></ol></li><li>baz</li></ol>"
      end

      test "converts nested mixed lists" do
        assert_renders_textile "\n\n* foo\n## bar\n## baz\n*** quux\n* cuack\n\n",
                               "<ul><li>foo<ol><li>bar</li><li>baz<ul><li>quux</li></ul></li></ol></li><li>cuack</li></ul>"
      end
    end
  end
end
