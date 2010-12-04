# coding : utf-8

require "vcdom/node"

module VCDOM
    class AttrNodeMap #< NamedNodeMap
    
      include Enumerable
      
      def initialize( nodes )
        @nodes = nodes
      end
      def item( index )
        @nodes[index]
      end
      def length
        @nodes.length
      end
      def each
        @nodes.each do |n|
          yield n
        end
      end
      
      def inspect
        "#<VCXML::DOM::AttrNodeMap>"
      end
      
    end
end
