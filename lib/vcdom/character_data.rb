# coding : utf-8

require "vcdom/node"

module VCDOM
    class CharacterData < Node
      
      def initialize( doc, data )
        super( doc )
        @data = data.intern
      end
      
      def data
        @data.to_s
      end
      def data=( val )
        @data = val.intern
      end
      alias :node_value    :data
      alias :node_value=   :data=
      alias :text_content  :data
      alias :text_content= :data=
      
      def length
        @data.to_s.length
      end
      
    end
end
