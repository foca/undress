require "hpricot"

module Rainbow
  def self.new(document)
    Parser.new(document)
  end

  class Parser
    attr_reader :doc

    def initialize(document)
      @doc = Hpricot(document)
    end

    def to_textile
      Textile.process(doc.children)
    end

    class Grammar
      class << self
        def rule(*tags, &handler)
          tags.each {|t| processing_rules[t.to_sym] = handler }
        end

        def default(&handler)
          default_rule = handler
        end

        def process(nodes)
          Array(nodes).map do |node|
            if node.text?
              node.to_s
            elsif node.elem?
              (processing_rules[node.name.to_sym] || default_rule).call(node)
            else
              ""
            end
          end.join("")
        end

        def content_of(node)
          if node.text?
            node.to_s
          else
            process(node.children)
          end
        end

        def surrounded_by_whitespace?(node)
          node.previous.text? && node.previous.to_s =~ /\s+$/ || node.next.text? && node.next.to_s =~ /^\s+/
        end

        private

          def processing_rules
            @processing_rules ||= {}
          end

          def default_rule
            @default_rule ||= lambda {|e| process(e.children) }
          end
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
      rule(:blockquote) {|e| "bq. #{content_of(e)}\n" }
      rule(:pre)        {|e|
        if e.children.all? {|n| n.text? && n.content =~ /^\s+$/ || n.elem? && n.name == "code" }
          "pc. #{content_of(e % "code")}\n"
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

    class ::Hpricot::Text
      def children; self; end
    end

    class ::Hpricot::Elem
      def ancestors
        node, ancestors = parent, Elements[]
        while node.respond_to?(:parent) && node.parent
          ancestors << node
          node = node.parent
        end
        ancestors
      end
    end
  end
end
