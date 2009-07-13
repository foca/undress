module RainbowCloth
  class Grammar
    class << self
      def rule_for(*tags, &handler)
        tags.each {|t| processing_rules[t.to_sym] = handler }
      end

      def default(&handler)
        @default_rule = handler
      end

      def post_processing(regexp, replacement = nil, &handler)
        post_processing_rules[regexp.freeze] = replacement || handler
      end

      def process(nodes)
        Array(nodes).map do |node|
          if node.text?
            node.to_html
          elsif node.elem?
            (processing_rules[node.name.to_sym] || default_rule).call(node)
          else
            ""
          end
        end.join("")
      end

      def process!(node)
        process(node.children).tap do |text|
          post_processing_rules.each do |rule, handler|
            handler.is_a?(String) ?  text.gsub!(rule, handler) : text.gsub!(rule, &handler)
          end
        end
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

        def post_processing_rules
          @post_processing_rules ||= {}
        end

        def processing_rules
          @processing_rules ||= {}
        end

        def default_rule
          @default_rule ||= lambda {|e| process(e.children) }
        end
    end
  end
end
