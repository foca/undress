module RainbowCloth
  class Grammar
    def self.inherited(base)
      base.instance_variable_set(:@post_processing_rules, post_processing_rules)
      base.instance_variable_set(:@pre_processing_rules, pre_processing_rules)
    end

    def self.rule_for(*tags, &handler)
      tags.each do |tag|
        define_method tag.to_sym, &handler
      end
    end

    def self.default(&handler)
      define_method :method_missing do |tag, node, *args|
        handler.call(node)
      end
    end

    def self.post_processing(regexp, replacement = nil, &handler)
      post_processing_rules[regexp] = replacement || handler
    end

    def self.post_processing_rules
      @post_processing_rules ||= {}
    end

    def self.pre_processing(selector, &handler)
      pre_processing_rules[selector] = handler
    end

    def self.pre_processing_rules
      @pre_processing_rules ||= {}
    end

    def self.process!(node)
      new.process!(node)
    end

    attr_reader :pre_processing_rules, :post_processing_rules

    def initialize
      @pre_processing_rules = self.class.pre_processing_rules.dup
      @post_processing_rules = self.class.post_processing_rules.dup
    end

    def process(nodes)
      Array(nodes).map do |node|
        if node.text?
          node.to_html
        elsif node.elem?
          send node.name.to_sym, node
        else
          ""
        end
      end.join("")
    end

    def process!(node)
      pre_processing_rules.each do |selector, handler|
        node.search(selector).each(&handler)
      end

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

    def method_missing(tag, node, *args)
      process(node.children)
    end
  end
end
