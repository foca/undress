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
        "[#{process(e.children)}#{title}:#{e["href"]}]"
      }
      rule(:img) {|e|
        alt = e.has_attribute?("alt") ? "(#{e["alt"]})" : ""
        "!#{e["src"]}#{alt}!"
      }
      rule(:strong) {|e| "*#{process(e.children)}*" }
      rule(:em)     {|e| "_#{process(e.children)}_" }
      rule(:code)   {|e| "@#{process(e.children)}@" }
      rule(:cite)   {|e| "??#{process(e.children)}??" }
      rule(:sup)    {|e| surrounded_by_whitespace?(e) ? "^#{process(e.children)}^" : "[^#{process(e.children)}^]" }
      rule(:sub)    {|e| surrounded_by_whitespace?(e) ? "~#{process(e.children)}~" : "[~#{process(e.children)}~]" }
      rule(:ins)    {|e| "+#{process(e.children)}+" }
      rule(:del)    {|e| "-#{process(e.children)}-" }

      # text formatting and layout
      rule(:p)          {|e| "\n\n#{process(e.children)}\n\n" }
      rule(:br)         {|e| "\n" }
      rule(:blockquote) {|e| "bq. #{process(e.children)}\n" }
      rule(:pre)        {|e|
        if e.children.all? {|n| n.text? && n.content =~ /^\s+$/ || n.elem? && n.name == "code" }
          "pc. #{process((e % "code").children)}\n"
        else
          "<pre>#{process(e.children)}</pre>"
        end
      }

      # headings
      rule(:h1) {|e| "\n\nh1. #{process(e.children)}\n\n" }
      rule(:h2) {|e| "\n\nh2. #{process(e.children)}\n\n" }
      rule(:h3) {|e| "\n\nh3. #{process(e.children)}\n\n" }
      rule(:h4) {|e| "\n\nh4. #{process(e.children)}\n\n" }
      rule(:h5) {|e| "\n\nh5. #{process(e.children)}\n\n" }
      rule(:h6) {|e| "\n\nh6. #{process(e.children)}\n\n" }

      # lists
      rule(:li) {|e|
        token = e.parent.name == "ul" ? "*" : "#"
        nesting = e.ancestors.inject(1) {|total,node| total + (%(ul ol).include?(node.name) ? 0 : 1) }
        "\n#{token * nesting} #{process(e.children)}"
      }
      rule(:ul, :ol) {|e|
        if e.ancestors.detect {|node| %(ul ol).include?(node.name) }
          process(e.children)
        else
          "\n#{process(e.children)}\n\n"
        end
      }

      # definition lists
      rule(:dl) {|e| "\n\n#{process(e.children)}\n" }
      rule(:dt) {|e| "- #{process(e.children)} " }
      rule(:dd) {|e| ":= #{process(e.children)} =:\n" }

      # tables
      rule(:table) {|e| "\n\n#{process(e.children)}\n" }
      rule(:tr) {|e| "#{process(e.children)}|\n" }
      rule(:td, :th) {|e|
        prefix = if e.name == "th"
          "_. "
        elsif e.has_attribute?("colspan")
          "\\#{e["colspan"]}. "
        elsif e.has_attribute?("rowspan")
          "/#{e["rowspan"]}. "
        end

        "|#{prefix}#{process(e.children)}" 
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
