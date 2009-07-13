require "hpricot"
require File.expand_path(File.dirname(__FILE__) + "/core_ext/object")
require File.expand_path(File.dirname(__FILE__) + "/undress/grammar")

def Undress(document, options={})
  Undress::Document.new(document, options)
end

module Undress
  class Document
    def initialize(document, options)
      @doc = Hpricot(document, options)
    end

    def self.add_markup(name, grammar)
      define_method "to_#{name}" do
        grammar.process!(@doc)
      end
    end
  end

  def self.add_markup(name, grammar)
    Document.add_markup(name, grammar)
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
