module RainbowCloth
  class Parser
    def to_textile
      Textile.process(doc.children)
    end
  end

  class Textile < Grammar
    # inline elements
    rule(:a) {|e|
      title = e.has_attribute?("title") ? " (#{e["title"]})" : ""
      "[#{content_of(e)}#{title}:#{e["href"]}]"
    }
    rule(:img) {|e|
      alt = e.has_attribute?("alt") ? "(#{e["alt"]})" : ""
      "!#{e["src"]}#{alt}!"
    }
    rule(:strong) {|e| "*#{content_of(e)}*" }
    rule(:em)     {|e| "_#{content_of(e)}_" }
    rule(:code)   {|e| "@#{content_of(e)}@" }
    rule(:cite)   {|e| "??#{content_of(e)}??" }
    rule(:sup)    {|e| surrounded_by_whitespace?(e) ? "^#{content_of(e)}^" : "[^#{content_of(e)}^]" }
    rule(:sub)    {|e| surrounded_by_whitespace?(e) ? "~#{content_of(e)}~" : "[~#{content_of(e)}~]" }
    rule(:ins)    {|e| "+#{content_of(e)}+" }
    rule(:del)    {|e| "-#{content_of(e)}-" }

    # text formatting and layout
    rule(:p)          {|e| "\n\n#{content_of(e)}\n\n" }
    rule(:br)         {|e| "\n" }
    rule(:blockquote) {|e| "\n\nbq. #{content_of(e)}\n\n" }
    rule(:pre)        {|e|
      if e.children.all? {|n| n.text? && n.content =~ /^\s+$/ || n.elem? && n.name == "code" }
        "\n\npc. #{content_of(e % "code")}\n\n"
      else
        "<pre>#{content_of(e)}</pre>"
      end
    }

    # headings
    rule(:h1) {|e| "\n\nh1. #{content_of(e)}\n\n" }
    rule(:h2) {|e| "\n\nh2. #{content_of(e)}\n\n" }
    rule(:h3) {|e| "\n\nh3. #{content_of(e)}\n\n" }
    rule(:h4) {|e| "\n\nh4. #{content_of(e)}\n\n" }
    rule(:h5) {|e| "\n\nh5. #{content_of(e)}\n\n" }
    rule(:h6) {|e| "\n\nh6. #{content_of(e)}\n\n" }

    # lists
    rule(:li) {|e|
      token = e.parent.name == "ul" ? "*" : "#"
      nesting = e.ancestors.inject(1) {|total,node| total + (%(ul ol).include?(node.name) ? 0 : 1) }
      "\n#{token * nesting} #{content_of(e)}"
    }
    rule(:ul, :ol) {|e|
      if e.ancestors.detect {|node| %(ul ol).include?(node.name) }
        content_of(e)
      else
        "\n#{content_of(e)}\n\n"
      end
    }

    # definition lists
    rule(:dl) {|e| "\n\n#{content_of(e)}\n" }
    rule(:dt) {|e| "- #{content_of(e)} " }
    rule(:dd) {|e| ":= #{content_of(e)} =:\n" }

    # tables
    rule(:table) {|e| "\n\n#{content_of(e)}\n" }
    rule(:tr) {|e| "#{content_of(e)}|\n" }
    rule(:td, :th) {|e|
      prefix = if e.name == "th"
        "_. "
      elsif e.has_attribute?("colspan")
        "\\#{e["colspan"]}. "
      elsif e.has_attribute?("rowspan")
        "/#{e["rowspan"]}. "
      end

      "|#{prefix}#{content_of(e)}" 
    }
  end
end
