module RainbowCloth
  class Grammar
    def self.inherited(child)
      child.instance_variable_set(:@processing_rules,      @processing_rules)
      child.instance_variable_set(:@post_processing_rules, @post_processing_rules)
      child.instance_variable_set(:@default_rule,          @default_rule)
    end

    def self.rule_for(*tags, &handler)
      tags.each {|t| processing_rules[t.to_sym] = handler }
    end

    def self.default(&handler)
      @default_rule = handler
    end

    def self.post_processing(regexp, replacement = nil, &handler)
      post_processing_rules[regexp] = replacement || handler
    end

    def self.pre_processing(selector, &handler)
      pre_processing_rules[selector] = handler
    end

    def self.process(nodes)
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

    def self.process!(node)
      pre_processing_rules.each do |selector, handler|
        node.search(selector).each(&handler)
      end

      process(node.children).tap do |text|
        post_processing_rules.each do |rule, handler|
          handler.is_a?(String) ?  text.gsub!(rule, handler) : text.gsub!(rule, &handler)
        end
      end
    end

    def self.content_of(node)
      if node.text?
        node.to_s
      else
        process(node.children)
      end
    end

    def self.surrounded_by_whitespace?(node)
      node.previous.text? && node.previous.to_s =~ /\s+$/ || node.next.text? && node.next.to_s =~ /^\s+/
    end

    def self.pre_processing_rules
      @pre_processing_rules ||= {}
    end
    private_class_method :pre_processing_rules

    def self.post_processing_rules
      @post_processing_rules ||= {}
    end
    private_class_method :post_processing_rules

    def self.processing_rules
      @processing_rules ||= {}
    end
    private_class_method :processing_rules

    def self.default_rule
      @default_rule ||= lambda {|e| process(e.children) }
    end
    private_class_method :default_rule
  end
end
