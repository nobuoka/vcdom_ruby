# coding : utf-8

require "vcdom/node"

module VCDOM
    class XMLSerializer
      
      def write_to_string( node )
        str = String.new
        _write_to_string( node, str )
        str
      end
      
      def _write_to_string( node, str )
        case node.node_type
          when Node::DOCUMENT_NODE then
            node.each_child_node do |n|
              _write_to_string( n, str )
            end
          when Node::ELEMENT_NODE then
            str << "<#{node.tag_name}"
            _write_to_string_attrs( node, str )
            str << ">"
            node.each_child_node do |n|
              _write_to_string( n, str )
            end
            str << "</#{node.tag_name}>"
          when Node::TEXT_NODE then
            str << node.data
          else
            raise "NOT SUPPORTED: " + node.inspect
        end
      end
      private :_write_to_string
      
      def _write_to_string_attrs( node, str )
        node.each_attr_node do |n|
          str << " "
          str << n.name
          str << "=\""
          n.each_child_node do |c|
            case c.node_type
              when Node::TEXT_NODE then
                str << c.data
              else
                raise "SORRY... UNSUPORTED"
            end
          end
          str << "\""
        end
      end
      private :_write_to_string
      
    end
end
