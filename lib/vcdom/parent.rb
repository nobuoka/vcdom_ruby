# coding : utf-8

require "vcdom/node_list"

module VCDOM
    module Parent
      
      class ChildNodes
        def initialize()
          @first_child = nil
          @last_child  = nil
          @length      = 0
        end
        def first_child; @first_child end
        def first_child=(c); @first_child = c end
        def last_child; @last_child end
        def last_child=(c); @last_child = c end
        def length; @length end
        def length=(c); @length = c end
        
        def each
          node = @first_child
          while not node.nil? do
            yield node
            node = node.next_sibling
          end
        end
        def []( index )
          if index >= 0 then
            node = @first_child
            index.times do
              if node.nil? then
                return node
              end
              node = node.next_sibling
            end
          elsif index < 0 then
            node = @last_child
            index *= -1
            index -= 1
            index.times do
              if node.nil? then
                return node
              end
              node = node.next_sibling
            end
          else
            raise "ERROR"
          end
          return node
        end
      end
      
      def initialize_parent()
        @child_nodes = ChildNodes.new()
      end
      
      def each_child_node
        @child_nodes.each do |n|
          yield n
        end
      end
      def child_nodes
        NodeList.new( @child_nodes )
      end
      def first_child
        @child_nodes.first_child
      end
      def last_child
        @child_nodes.last_child
      end
      
      def _append_child( new_child )
        #@child_nodes << new_child
        if not new_child.parent_node.nil? then
          # æ‘c‚ª‘¶Ý‚·‚é
          # new_child ‚ªŽ©•ª‚Ìæ‘c‚¶‚á‚È‚¢‚©Šm”F‚·‚é
          node = self.parent_node
          while not node.nil? do
            if node.equal? new_child then
              raise "HIERARCHY_REQUEST_ERR"
            end
            node = node.parent_node
          end
          # new_child ‚ð‚Æ‚è‚ ‚¦‚¸ƒcƒŠ[‚©‚çíœ
          new_child.parent_node.remove_child( new_child )
        end
        new_child._set_parent_node( self )
        if @child_nodes.last_child.nil? then
          @child_nodes.first_child = new_child
        else
          @child_nodes.last_child._set_next_sibling( new_child )
        end
        @child_nodes.last_child  = new_child
        @child_nodes.length += 1
        new_child
      end
      private :_append_child
      def <<( new_child )
        self.append_child( new_child )
        self
      end
      def remove_child( old_child )
        if not old_child.is_a? Node then
          raise ArgumentError.new()
        end
        if old_child.parent_node and old_child.parent_node.equal? self then
          @child_nodes.length -= 1
        else
          raise "ERROR"
        end
        if @child_nodes.first_child.equal? old_child then
          @child_nodes.first_child = old_child.next_sibling
        end
        if @child_nodes.last_child.equal? old_child then
          @child_nodes.last_child = old_child.previous_sibling
        end
        old_child._leave_from_tree()
        return old_child
      end
      def []( index )
        @child_nodes[index]
      end
      
    end
end
