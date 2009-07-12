require "hpricot"

module Rainbow
  class HTML
    attr_reader :doc

    def initialize(document)
      @doc = Hpricot(document)
    end

    def to_textile
      self.class.textilize(doc.children)
    end

    def self.textilize(nodes)
      Array(nodes).map do |node|
        if node.text?
          node.to_s
        elsif node.elem?
          (MAPPINGS[node.name.to_sym] || MAPPINGS[:*])[node]
        else
          ""
        end
      end.join("")
    end

    def self.surrounded_by_whitespace?(node)
      node.previous.text? && node.previous.to_s =~ /\s+$/ || node.next.text? && node.next.to_s =~ /^\s+/
    end

    MAPPINGS = {
      # inline elements
      :a       => lambda {|e|
                    title = e.has_attribute?("title") ? " (#{e["title"]})" : ""
                    "[#{textilize(e.children)}#{title}:#{e["href"]}]"
                  },
      :img     => lambda {|e|
                    alt = e.has_attribute?("alt") ? "(#{e["alt"]})" : ""
                    "!#{e["src"]}#{alt}!"
                  },
      :strong  => lambda {|e| "*#{textilize(e.children)}*" },
      :em      => lambda {|e| "_#{textilize(e.children)}_" },
      :code    => lambda {|e| "@#{textilize(e.children)}@" },
      :cite    => lambda {|e| "??#{textilize(e.children)}??" },
      :sup     => lambda {|e| surrounded_by_whitespace?(e) ? "^#{textilize(e.children)}^" : "[^#{textilize(e.children)}^]" },
      :sub     => lambda {|e| surrounded_by_whitespace?(e) ? "~#{textilize(e.children)}~" : "[~#{textilize(e.children)}~]" },
      :ins     => lambda {|e| "+#{textilize(e.children)}+" },
      :del     => lambda {|e| "-#{textilize(e.children)}-" },

      # headings
      :h1      => lambda {|e| "\n\nh1. #{textilize(e.children)}\n\n" },
      :h2      => lambda {|e| "\n\nh2. #{textilize(e.children)}\n\n" },
      :h3      => lambda {|e| "\n\nh3. #{textilize(e.children)}\n\n" },
      :h4      => lambda {|e| "\n\nh4. #{textilize(e.children)}\n\n" },
      :h5      => lambda {|e| "\n\nh5. #{textilize(e.children)}\n\n" },
      :h6      => lambda {|e| "\n\nh6. #{textilize(e.children)}\n\n" },

      # lists
      :li      => lambda {|e|
                    token = e.parent.name == "ul" ? "*" : "#"
                    nesting = e.ancestors.inject(1) {|total,node| total + (%(ul ol).include?(node.name) ? 0 : 1) }
                    "\n#{token * nesting} #{textilize(e.children)}"
                  },
      :ul      => list_processor = lambda {|e|
                    if e.ancestors.detect {|node| %(ul ol).include?(node.name) }
                      textilize(e.children)
                    else
                      "\n#{textilize(e.children)}\n\n"
                    end
                  },
      :ol      => list_processor,

      # anything else
      :* => lambda {|e| textilize(e.children) }
    }

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
