# coding : utf-8

require "vcdom/node"
require "vcdom/parent"

module VCDOM
    class Attr < Node
      
      include Parent
      
      def initialize( doc, name ) # :nodoc:
        initialize_parent()
        super( doc )
        @owner_element  = nil
        @local_name     = name
      end
      
      def node_type
        ATTRIBUTE_NODE
      end
      
      def owner_element
        @owner_element
      end
      def _set_owner_element( elem ) # :nodoc:
        @owner_element = elem
      end
      
      def name
        @local_name.to_s()
      end
      alias :node_name :name
      
      def local_name
        nil
      end
      
      def value
        val = String.new()
        self.each_child_node do |n|
          # Text のみを考慮
          val << n.node_value
        end
        return val
      end
      def value=(val)
        while self.first_child do
          self.remove_child( self.first_child )
        end
        self.append_child( self.owner_document.create_text_node( val ) )
      end
      
      def append_child( new_child )
        # ノードのタイプチェックなど
        if not new_child.is_a? Node then
          raise ArgumentError.new( "the argument [#{new_child.inspect}] is not an object of the expected class." )
        end
        # Text, EntityReference
        case new_child.node_type
          when TEXT_NODE, ENTITY_REFERENCE_NODE then
            # OK
          else
            # ERROR
            raise "ERROR"
        end
        _append_child( new_child )
      end
      
    end
end
