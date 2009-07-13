require "hpricot"

require File.expand_path(File.dirname(__FILE__) + "/core_ext/object")
require File.expand_path(File.dirname(__FILE__) + "/rainbow_cloth/grammar")
require File.expand_path(File.dirname(__FILE__) + "/rainbow_cloth/textile")

module RainbowCloth
  def self.new(document)
    Document.new(document)
  end

  class Document
    attr_reader :doc

    def initialize(document)
      @doc = Hpricot(document)
    end
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
