require "hpricot"

require File.expand_path(File.dirname(__FILE__) + "/rainbow_cloth/grammar")
require File.expand_path(File.dirname(__FILE__) + "/rainbow_cloth/textile")

module RainbowCloth
  def self.new(document)
    Parser.new(document)
  end

  class Parser
    attr_reader :doc

    def initialize(document)
      @doc = Hpricot(document)
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
