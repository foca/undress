module RainbowCloth
  class Grammar
    class << self
      def rule_for(*tags, &handler)
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
end
