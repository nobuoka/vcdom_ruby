# coding : utf-8

require "vcdom/node_list"

module VCDOM
    module Child
      
      def initialize_child()
        @parent_node  = nil
        @next_sibling = nil
        @prev_sibling = nil
      end
      
      def parent_node
        @parent_node
      end
      def _set_parent_node( parent_node )
        @parent_node = parent_node
      end
      def _set_next_sibling( next_node )
        next_node.previous_sibling = self
        next_node.next_sibling = self.next_sibling
        self.next_sibling.previous_sibling = next_node until self.next_sibling.nil?
        self.next_sibling = next_node
      end
      def previous_sibling
        @prev_sibling
      end
      def previous_sibling=(node)
        @prev_sibling = node
      end
      protected :previous_sibling=
      def next_sibling
        @next_sibling
      end
      def next_sibling=(node)
        @next_sibling = node
      end
      protected :next_sibling=
      def _leave_from_tree()
        @parent_node = nil
        if @next_sibling then
          @next_sibling.previous_sibling = @prev_sibling
          @next_sibling = nil
        end
        if @prev_sibling then
          @prev_sibling.next_sibling     = @next_sibling
          @prev_sibling = nil
        end
      end
      
    end
end
