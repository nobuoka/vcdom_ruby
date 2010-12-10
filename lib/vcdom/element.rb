# coding : utf-8

require "vcdom/node"
require "vcdom/parent"
require "vcdom/child"
require "vcdom/attr_node_map"

module VCDOM
    class Element < Node
      
      include Parent
      include Child
      
      def initialize( doc, tag_name ) # :nodoc:
        initialize_parent()
        super( doc )
        @local_name = tag_name
        # attributes
        @attr_nodes = Array.new()
        @attr_node_map = AttrNodeMap.new( @attr_nodes )
      end
      
      def node_type
        ELEMENT_NODE
      end
      
      def tag_name
        @local_name.to_s()
      end
      alias :node_name :tag_name
      
      def local_name
        nil
      end
      
      def append_child( new_child )
        # ノードのタイプチェックなど
        if not new_child.is_a? Node then
          raise ArgumentError.new( "the argument [#{new_child.inspect}] is not an object of the expected class." )
        end
        # Element, Text, Comment, ProcessingInstruction, CDATASection, EntityReference
        case new_child.node_type
          when ELEMENT_NODE, TEXT_NODE, CDATA_SECTION_NODE, ENTITY_REFERENCE_NODE, PROCESSING_INSTRUCTION_NODE, COMMENT_NODE then
            # OK
          else
            # ERROR
            raise "ERROR"
        end
        _append_child( new_child )
      end
      
      # attributes
      def attributes
        @attr_node_map
      end
      def each_attr_node
        @attr_nodes.each do |n|
          yield n
        end
      end
      
      # setAttributeNode
      # Adds a new attribute node. If an attribute with that name (nodeName) is already present in the element, 
      # it is replaced by the new one. Replacing an attribute node by itself has no effect.
      # To add a new attribute node with a qualified name and namespace URI, use the setAttributeNodeNS method.
      # @param new_attr The Attr node to add to the attribute list.
      # @return If the newAttr attribute replaces an existing attribute, the replaced Attr node is returned, 
      #         otherwise null is returned.
      def set_attribute_node( new_attr )
        if new_attr.owner_document != self.owner_document then
          raise "WRONG_DOCUMENT_ERR"
        end
        if not new_attr.owner_element.nil? then
          raise "INUSE_ATTRIBUTE_ERR"
        end
        old_attr = nil
        @attr_nodes << new_attr
        new_attr._set_owner_element( self )
        old_attr
      end
      def set_attribute( name, value )
        attr = self.owner_document.create_attribute( name )
        attr.append_child( self.owner_document.create_text_node( value ) )
        self.set_attribute_node( attr )
        nil
      end
      
      # setAttributeNodeNS introduced in DOM Level 2
      # Adds a new attribute. If an attribute with that local name and that namespace URI is already present in the element, it is replaced by the new one. Replacing an attribute node by itself has no effect.
      # Per [XML Namespaces], applications must use the value null as the namespaceURI parameter for methods if they wish to have no namespace.
      # @param new_attr The Attr node to add to the attribute list.
      # @return If the newAttr attribute replaces an existing attribute with the same local name and namespace URI, the replaced Attr node is returned, otherwise null is returned.
      def set_attribute_node_ns( new_attr )
        if new_attr.owner_document != self.owner_document then
          raise "WRONG_DOCUMENT_ERR"
        end
        if not new_attr.owner_element.nil? then
          raise "INUSE_ATTRIBUTE_ERR"
        end
        old_attr = nil
        @attr_nodes << new_attr
        new_attr._set_owner_element( self )
        old_attr
      end
      def set_attribute_ns( namespace_uri, qualified_name, value )
        attr = self.owner_document.create_attribute_ns( namespace_uri, qualified_name )
        attr.append_child( self.owner_document.create_text_node( value ) )
        self.set_attribute_node_ns( attr )
        nil
      end
      def get_attribute_ns( namespace_uri, local_name )
        @attr_nodes.each do |attr|
          if attr.namespace_uri == namespace_uri and attr.local_name == local_name then
            #//////////////////////////
            # 変更する
            #//////////////////////////
            return attr.value
          end
        end
        return ""
      end
      
      
      
      
      
      # 1. 要素が ns uri を持ってるかどうか確認
      # 1-1. ns uri を持つ : prefix/uri ペア (prefix が nil もあり) の宣言がスコープ内にあるかどうか調べる
      # 1-1-1. スコープ内にない : 要素の prefix の ns 宣言をする (nil の場合はデフォルト ns 宣言) 既に同じ prefix の宣言があるなら上書きする
      # 1-2. ns uri を持たない : 要素が localName を持つかどうか確認
      # 1-2-1 localName を持たない : 不明
      # 1-2-2 localName を持つ : デフォルト ns 宣言が nil じゃないなら, この要素に nil のデフォルト ns 宣言を付ける
                            # prefix があって ns uri が nil というのは許されない!!!!
      # 2. ns 宣言以外の属性を 1 個取り出し attr とする
      # 3. attr が nil でないなら 4 へ
      # 4. attr が ns を持っているか
      # 4-1. ns あり : prefix がないか, prefix が宣言されてないか, prefix が既に別の ns に結び付けられている
      # 4-1-1. prefix がダメ : ns に結び付けられている prefix が既にあるかどうか
      # 4-1-1-1. ある : prefix をそれに変える
      # 4-1-1-2. ない : prefix が nil でなく, まだスコープ内で宣言されていないか
      # 4-1-1-2-1. 宣言されてない : 宣言する
      # 4-1-1-2-2. prefix が nil または宣言されている : NS+index という prefix (まだ宣言されていないもの) に変え, 宣言する
      # 4-2. ns なし : localName を持っているかどうか
      # 4-2-1. localName なし : 不明
      # 4-2-2. localName あり : 何もしない
      
      #void Element.normalizeNamespaces()
      def normalize_namespaces()
        # non-namespace Attrs of Element
        non_ns_attrs = Array.new()
        # Pick up local namespace declarations
        # for ( all DOM Level 2 valid local namespace declaration attributes of Element ) {
        #   if (the namespace declaration is invalid) {
        #     Note: The prefix xmlns is used only to declare namespace bindings and
        #     is by definition bound to the namespace name http://www.w3.org/2000/xmlns/.
        #     It must not be declared. No other prefix may be bound to this namespace name.         
        #       ==> Report an error.
        #   } else {
        #       ==>  Record the namespace declaration
        #   }
        # }
        #ns = Hash.new()
        @attr_nodes.each do |n|
          if n.name == "xmlns" then
          #  ns[nil] = n[0].data
          elsif n.prefix == "xmlns" then
          #  ns[n.local_name.intern] = n[0].data
          else
            non_ns_attrs << n
          end
        end
        
        # Fixup element's namespace
        if self.namespace_uri then
          # when Element's namespaceURI is not nil
          # prefix / ns ペアが既にスコープ内に存在するかどうかの確認
          # この flag チェックは変更しないとダメかも...
          flag = false
          if self.prefix.nil? then
            #///////////////////////////////////
            # is_default_namespace だとダメー
            #///////////////////////////////////
            #if self.is_default_namespace( self.namespace_uri ) then
            #  flag = true
            #end
            n = self
            loop do
              if n.nil? then
                break
              elsif n.node_type == ELEMENT_NODE then
                if n.get_attribute_ns( "http://www.w3.org/2000/xmlns/", "xmlns" ) == self.namespace_uri then
                  flag = true
                  break
                end
              end
              n = n.parent_node
            end
          else
            #///////////////////////////////////
            # lookup_namespace_uri だとダメー
            #///////////////////////////////////
            #if self.lookup_namespace_uri( self.prefix ) == self.namespace_uri then
            #  flag = true
            #end
            if self.prefix == "xml" then
              # ok?
              flag = true
            else
              n = self
              loop do
                if n.nil? then
                  break
                elsif n.node_type == ELEMENT_NODE then
                  if n.get_attribute_ns( "http://www.w3.org/2000/xmlns/", self.prefix ) == self.namespace_uri then
                    flag = true
                    break
                  end
                end
                n = n.parent_node
              end
            end
          end
          if flag then
            # when Element's prefix/namespace pair (or default namespace, if no prefix) are within the scope of a binding
            #    ==> do nothing, declaration in scope is inherited
            # See section "B.1.1: Scope of a binding" for an example
          else
            # ==> Create a local namespace declaration attr for this namespace,
            #          with Element's current prefix (or a default namespace, if
            #          no prefix). If there's a conflicting local declaration
            #          already present, change its value to use this namespace.
            #          See section "B.1.2: Conflicting namespace declaration" for an example
            #          // NOTE that this may break other nodes within this Element's
            #          // subtree, if they're already using this prefix.
            #          // They will be repaired when we reach them.
            if self.prefix.nil? then
              self.set_attribute_ns( "http://www.w3.org/2000/xmlns/", "xmlns", self.namespace_uri )
            else
              self.set_attribute_ns( "http://www.w3.org/2000/xmlns/", "xmlns:#{self.prefix}", self.namespace_uri )
            end
          end
        else
          # when Element has no namespace URI:
          if self.local_name.nil? then
            # when Element's localName is null
            #       // DOM Level 1 node
            #       ==> if in process of validation against a namespace aware schema 
            #           (i.e XML Schema) report a fatal error: the processor can not recover 
            #           in this situation. 
            #           Otherwise, report an error: no namespace fixup will be performed on this node.
          else
            # when Element has no pseudo-prefix
            if self.prefix.nil? and not self.is_default_namespace( nil ) then
              # when there's a conflicting local default namespace declaration already present
              #        ==> change its value to use this empty namespace.
              self.set_attribute_ns( "http://www.w3.org/2000/xmlns/", "xmlns", "" )
            elsif self.prefix and self.lookup_prefix( nil ) == self.prefix then
              self.set_attribute_ns( "http://www.w3.org/2000/xmlns/", "xmlns:#{self.prefix}", "" )
            end
            #      // NOTE that this may break other nodes within this Element's
            #      // subtree, if they're already using the default namespaces.
            #      // They will be repaired when we reach them.
          end
        end
        
        # Examine and polish the attributes
        #for ( all non-namespace Attrs of Element )
        non_ns_attrs.each do |attr|
          if attr.namespace_uri then
            if attr.prefix == "xml" then
              # do nothing
            # when attr has a namespace URI
            elsif attr.prefix.nil? or self.lookup_namespace_uri( attr.prefix ) != attr.namespace_uri then
              # when attribute has no prefix (default namespace decl does not apply to attributes) 
              # OR attribute prefix is not declared OR conflict: attribute has a prefix that conflicts with a binding
              #        already active in scope)
              if not (new_prefix = self.lookup_prefix( attr.namespace_uri )).nil? then
                # when (namespaceURI matches an in scope declaration of one or more prefixes)
                # pick the most local binding available; 
                # if there is more than one pick one arbitrarily
                # ==> change attribute's prefix.
                attr.prefix = new_prefix
              else
                if not attr.prefix.nil? and self.lookup_namespace_uri( attr.prefix ).nil? then
                  # when the current prefix is not null and it has no in scope declaration
                  # ==> declare this prefix
                  self.set_attribute_ns( "http://www.w3.org/2000/xmlns/", "xmlns:#{attr.prefix}", attr.namespace_uri )
                else
                  # find a prefix following the pattern "NS" +index (starting at 1)
                  # make sure this prefix is not declared in the current scope.
                  # create a local namespace declaration attribute
                  #==> change attribute's prefix.
                  i = 0
                  loop do
                    i += 1
                    if self.lookup_namespace_uri( "NS#{i}" ).nil? then
                      self.set_attribute_ns( "http://www.w3.org/2000/xmlns/", "xmlns:NS#{i}", attr.namespace_uri )
                      break
                    end
                  end
                  attr.prefix = "NS#{i}"
                end
              end
            end
          else
            # attr has no namespace URI
            if attr.local_name.nil? then
              # when attr has no localName
              #   = DOM Level 1 node
              #==> if in process of validation against a namespace aware schema 
              #     (i.e XML Schema) report a fatal error: the processor can not recover 
              #      in this situation. 
              #      Otherwise, report an error: no namespace fixup will be performed on this node.
            else
              # attr has no namespace URI and no prefix
              # no action is required, since attrs don't use default
              # ==> do nothing 
            end
          end
        end # end for-all-Attrs
        
        # do this recursively
        #for ( all child elements of Element )
        self.each_child_node do |c|
          if c.node_type == ELEMENT_NODE then
            c.normalize_namespaces()
          end
        end # end Element.normalizeNamespaces
      end
      
      # The first child node of that element which is of nodeType +ELEMENT_NODE+, as an Element object.
      # If the element on which this attribute is accessed does not have any child nodes, 
      # or if none of those child nodes are element nodes, then this attribute return +nil+. 
      # (defiend at W3C Element Traversal Specification)
      def first_element_child
        n = self.first_child
        while n do
          if n.node_type == ELEMENT_NODE then
            break
          end
          n = n.next_sibling
        end
        return n
      end
      
      # The last child node of that element which is of nodeType +ELEMENT_NODE+, as an Element object.
      # If the element on which this attribute is accessed does not have any child nodes, 
      # or if none of those child nodes are element nodes, then this attribute return +nil+. 
      # (defiend at W3C Element Traversal Specification)
      def last_element_child
        n = self.last_child
        while n do
          if n.node_type == ELEMENT_NODE then
            break
          end
          n = n.previous_sibling
        end
        return n
      end
      
      # The sibling node of that element which most immediately precedes that element in document order, 
      # and which is of nodeType +ELEMENT_NODE+, as an Element object. 
      # If the element on which this attribute is accessed does not have any preceding sibling nodes, 
      # or if none of those preceding sibling nodes are element nodes, then this attribute must return +nil+. 
      # (defiend at W3C Element Traversal Specification)
      def previous_element_sibling
        n = self.previous_sibling
        while n do
          if n.node_type == ELEMENT_NODE then
            break
          end
          n = n.previous_sibling
        end
        return n
      end
      
      # The sibling node of that element which most immediately follows that element in document order, 
      # and which is of nodeType +ELEMENT_NODE+, as an Element object. 
      # If the element on which this attribute is accessed does not have any following sibling nodes, 
      # or if none of those following sibling nodes are element nodes, then this attribute must return +nil+. 
      # (defiend at W3C Element Traversal Specification)
      def next_element_sibling
        n = self.next_sibling
        while n do
          if n.node_type == ELEMENT_NODE then
            break
          end
          n = n.next_sibling
        end
        return n
      end
      
      # The current number of child nodes of that element which are of nodeType +ELEMENT_NODE+. 
      # This value is not stored, but calculated when you access this attribute. 
      def child_element_count
        num = 0
        self.each_child_node do |n|
          if n.node_type == ELEMENT_NODE then
            num += 1
          end
        end
        return num
      end
      
    end
end
