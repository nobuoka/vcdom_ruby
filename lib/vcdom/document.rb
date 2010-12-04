# coding : utf-8

require "vcdom/node"
require "vcdom/parent"
require "vcdom/element"
require "vcdom/element_ns"
require "vcdom/attr"
require "vcdom/attr_ns"
require "vcdom/text"

module VCDOM
    class Document < Node
      
      include Parent
      
      
      def initialize()
        initialize_parent()
        super( nil )
      end
      
      def node_type
        DOCUMENT_NODE
      end
      
      def append_child( new_child )
        # ノードのタイプチェックなど
        if not new_child.is_a? Node then
          raise ArgumentError.new( "the argument [#{new_child.inspect}] is not an object of the expected class." )
        end
        # Element (maximum of one), ProcessingInstruction, Comment, DocumentType (maximum of one) 
        case new_child.node_type
          when ELEMENT_NODE then
            # 既に追加されてるかどうかのチェック
            if @document_element.nil? then
              @document_element = new_child
            else
              raise "HIERARCHY_REQUEST_ERR"
            end
          when DOCUMENT_TYPE_NODE then
            # 既に追加されてるかどうかのチェック
          when PROCESSING_INSTRUCTION_NODE, COMMENT_NODE then
            # OK
          else
            # ERROR
            raise "ERROR"
        end
        _append_child( new_child )
      end
      
      def create_element( tag_name )
        elem = nil
        if tag_name.is_a? String then
          elem = Element._new( self, tag_name.intern )
        else
          raise "ERROR"
        end
        elem
      end
      
      def create_element_ns( namespace_uri, qualified_name )
        elem = nil
        if namespace_uri.is_a? String then
          namespace_uri = namespace_uri.intern
        elsif not namespace_uri.nil? then
          raise "ERROR"
        end
        if qualified_name.is_a? String then
          name_parts = qualified_name.split /:/
          if name_parts.length == 1 then
            elem = ElementNS._new( self, namespace_uri, nil, name_parts[0].intern )
          elsif name_parts.length == 2 then
            elem = ElementNS._new( self, namespace_uri, name_parts[0].intern, name_parts[1].intern )
          else
            raise "ERROR"
          end
        else
          raise "ERROR"
        end
        elem
      end
      
      def create_attribute( name )
        attr = nil
        if name.is_a? String then
          attr = Attr._new( self, name.intern )
        else
          raise ArgumentError.new( "the argument [#{new_child.inspect}] is not an object of the expected class." )
        end
        attr
      end
      
      def create_attribute_ns( namespace_uri, qualified_name )
        attr = nil
        if namespace_uri.is_a? String then
          namespace_uri = namespace_uri.intern
        elsif not namespace_uri.nil? then
          raise ArgumentError.new( "the argument *namespace_uri* must be a String object or nil." )
        end
        if qualified_name.is_a? String then
          name_parts = qualified_name.split /:/
          if name_parts.length == 1 then
            attr = AttrNS._new( self, namespace_uri, nil, name_parts[0].intern )
          elsif name_parts.length == 2 then
            attr = AttrNS._new( self, namespace_uri, name_parts[0].intern, name_parts[1].intern )
          else
            raise "ERROR"
          end
        else
          raise "ERROR"
        end
        attr
      end
      
      def create_text_node( data )
        node = nil
        if data.is_a? String then
          node = Text._new( self, data.intern )
        else
          raise ArgumentError.new( "the argument [#{data.inspect}] is not an object of the expected class. the class : #{data.class}" )
        end
        node
      end
      
    end
end
