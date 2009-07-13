require "hpricot"
require File.expand_path(File.dirname(__FILE__) + "/core_ext/object")
require File.expand_path(File.dirname(__FILE__) + "/undress/grammar")

# Load an HTML document so you can undress it. Pass it either a string or an IO
# object. You can pass an optional hash of options, which will be forwarded
# straight to Hpricot. Check it's
# documentation[http://code.whytheluckystiff.net/doc/hpricot] for details.
def Undress(html, options={})
  Undress::Document.new(html, options)
end

module Undress
  # Register a markup language. The name will become the method used to convert
  # HTML to this markup language: for example registering the name +:textile+
  # gives you <tt>Undress(code).to_textile</tt>, registering +:markdown+ would
  # give you <tt>Undress(code).to_markdown</tt>, etc.
  def self.add_markup(name, grammar)
    Document.add_markup(name, grammar)
  end

  class Document #:nodoc:
    def initialize(html, options)
      @doc = Hpricot(html, options)
    end

    def self.add_markup(name, grammar)
      define_method "to_#{name}" do
        grammar.process!(@doc)
      end
    end
  end

  module ::Hpricot #:nodoc:
    class Elem #:nodoc:
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
