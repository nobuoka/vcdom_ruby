# coding : utf-8

require "vcdom/node"

module VCDOM
    class CharacterData < Node
      
      def initialize( doc, data )
        super( doc )
        @data = data
      end
      
      def data
        @data.to_s
      end
      alias :node_value :data
      def length
        @data.to_s.length
      end
      
    end
end
