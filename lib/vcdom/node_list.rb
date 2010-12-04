# coding : utf-8

require "vcdom/node"

module VCDOM
    class NodeList
      
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
        "#<VCXML::DOM::NodeList>"
      end
      
      #EMPTY_NODE_LIST = NodeList.new( Array.new() )
      
    end
end
