# coding : utf-8

module VCDOM
    class Node
      
      ELEMENT_NODE                = :element_node
      ATTRIBUTE_NODE              = :attribute_node
      TEXT_NODE                   = :text_node
      CDATA_SECTION_NODE          = :cdata_section_node
      ENTITY_REFERENCE_NODE       = :entity_reference_node
      ENTITY_NODE                 = :entity_node
      PROCESSING_INSTRUCTION_NODE = :processing_instruction_node
      COMMENT_NODE                = :comment_node
      DOCUMENT_NODE               = :document_node
      DOCUMENT_TYPE_NODE          = :document_type_node
      DOCUMENT_FRAGMENT_NODE      = :document_fragment_node
      NOTATION_NODE               = :notation_node
      
      class << self
        alias :_new :new
        private :new
      end
      
      def initialize( owner_document ) # :nodoc:
        @owner_document = owner_document
      end
      
      def owner_document
        @owner_document
      end
      
      def prefix
        nil
      end
      def namespace_uri
        nil
      end
      
      def parent_node
        nil
      end
      def previous_sibling
        nil
      end
      def next_sibling
        nil
      end
      def node_value
        nil
      end
      def attributes
        nil
      end
      def node_list
        NodeList::EMPTY_NODE_LIST
      end
      def attributes
        nil
      end
      
      # Concatenation of the textContent attribute value of every child node, 
      # excluding +COMMENT_NODE+ and +PROCESSING_INSTRUCTION_NODE+ nodes. 
      # This is the empty string if the node has no children.
      def text_content
        str = String.new()
        self.each_child_node do |n|
          if n.node_type != COMMENT_NODE and n.node_type != PROCESSING_INSTRUCTION_NODE then
            str << n.text_content
          end
        end
        return str
      end
      
      # Any possible children this node have are removed and, if the new value is not empty +String+ object or +nil+, 
      # replaced by a single Text node containing the new value string. 
      def text_content=( val )
        n = self.first_child
        while n do
          self.remove_child( n )
          n = self.first_child
        end
        self.append_child( self.owner_document.create_text_node( val ) )
      end
      
      def lookup_prefix( namespace_uri )
        if namespace_uri.nil? then #(namespaceURI has no value, i.e. namespaceURI is null or empty string) {
          return nil
        end
        case self.node_type
          when ELEMENT_NODE then
            return lookup_namespace_prefix( namespace_uri, self )
          when DOCUMENT_NODE then
            #//////////////////////
            # これでいいの？
            #//////////////////////
            return self.document_element.lookup_namespace_prefix( namespace_uri, self )
          when ENTITY_NODE, NOTATION_NODE, DOCUMENT_FRAGMENT_NODE, DOCUMENT_TYPE_NODE then
            return nil # type is unknown  
          when ATTRIBUTE_NODE then
            if not self.owner_element.nil? then #( Attr has an owner Element ) 
            #//////////////////////
            # これでいいの？
            #//////////////////////
              return self.owner_element.lookup_namespace_prefix( namespace_uri, self )
            end
            return nil
          else
            anc_node = self.parent_node
            loop do
              if anc_node.nil? or anc_node.node_type == ELEMENT_NODE then
                break
              end
              anc_node = anc_node.parent_node
            end
            if not anc_node.nil? then
            #// EntityReferences may have to be skipped to get to it 
            #//////////////////////
            # これでいいの？
            #//////////////////////
              return anc_node.lookup_namespace_prefix( namespace_uri, self )
            end
            return nil
        end
      end
      
      # Always +false+.
      def has_child_nodes()
        return false
      end
      
      def compare_document_position( ref_node )
        # TODO
        self_preds = Array.new()
        ref_preds  = Array.new()
        node = self
        while node do
          self_preds.unshift node
          node = node.parent_node
        end
        node = ref_node
        while node do
          ref_preds.unshift node
          node = node.parent_node
        end
        i = 0
        while self_preds[i] and self_preds[i].equal? ref_preds[i] do i += 1 end
        if self_preds[i].nil? then
          return 
        end
      end
      
      def lookup_namespace_prefix( namespace_uri, original_element )
        if not self.namespace_uri.nil? and self.namespace_uri == namespace_uri and 
              not self.prefix.nil? and original_element.lookup_namespace_uri( self.prefix ) == namespace_uri then
          #( Element has a namespace and Element's namespace == namespaceURI and 
          #   Element has a prefix and 
          #originalElement.lookupNamespaceURI(Element's prefix) == namespaceURI) 
          return self.prefix
        end
        self.each_attr_node do |attr|
        #if #( Element has attributes) { 
        #for ( all DOM Level 2 valid local namespace declaration attributes of Element ) {
          #//////////////////////////
          # 要変更
          #//////////////////////////
          if attr.prefix == "xmlns" and attr[0].data == namespace_uri and 
                original_element.lookup_namespace_uri( attr.local_name ) == namespace_uri then
          #if (Attr's prefix == "xmlns" and Attr's value == namespaceURI and 
          #    originalElement.lookupNamespaceURI(Attr's localname) == namespaceURI) 
            return attr.local_name
          end
        #}
        end #} 
            anc_node = self.parent_node
            loop do
              if anc_node.nil? or anc_node.node_type == ELEMENT_NODE then
                break
              end
              anc_node = anc_node.parent_node
            end
            if not anc_node.nil? then
            #// EntityReferences may have to be skipped to get to it 
            #//////////////////////
            # これでいいの？
            #//////////////////////
              return anc_node.lookup_namespace_prefix( namespace_uri, original_element )
            end
        #if (Node has an ancestor Element ) 
        #   // EntityReferences may have to be skipped to get to it 
        #{ 
        #    return ancestor.lookupNamespacePrefix(namespaceURI, originalElement); 
        #} 
        return nil
      end

      
      def lookup_namespace_uri( prefix )
        case self.node_type
          when ELEMENT_NODE then
            if not self.namespace_uri.nil? and self.prefix == prefix then
              #( Element's namespace != null and Element's prefix == prefix ) 
              #  Note: prefix could be "null" in this case we are looking for default namespace 
              return self.namespace_uri
            end
            #if ( Element has attributes)
            #for ( all DOM Level 2 valid local namespace declaration attributes of Element )
            self.each_attr_node do |attr|
              if attr.prefix == "xmlns" and attr.local_name == prefix then
                #if (Attr's prefix == "xmlns" and Attr's localName == prefix ) 
                #         // non default namespace
                # /////////////////////
                #  変更が必要
                # /////////////////////
                if not attr[0].nil? then
                  #if (Attr's value is not empty) {
                  return attr[0].data
                end
                return nil
              elsif attr.local_name == "xmlns" and prefix == nil then
                #(Attr's localname == "xmlns" and prefix == null)
                #       // default namespace { 
                # /////////////////////
                #  変更が必要
                # /////////////////////
                if not attr[0].nil? then
                  # if (Attr's value is not empty) {
                  return attr[0].data
                end
                return nil
              end
            end
            anc_node = self.parent_node
            loop do
              if anc_node.nil? or anc_node.node_type == ELEMENT_NODE then
                break
              end
              anc_node = anc_node.parent_node
            end
            if not anc_node.nil? then
            #if ( Element has an ancestor Element ) 
            #// EntityReferences may have to be skipped to get to it { 
              return anc_node.lookup_namespace_uri( prefix )
            end
            return nil
          when DOCUMENT_NODE then
            return self.document_element.lookup_namespace_uri( prefix )
          when ENTITY_NODE, NOTATION_NODE, DOCUMENT_TYPE_NODE, DOCUMENT_FRAGMENT_NODE then
            return nil
          when ATTRIBUTE_NODE then
            if not self.owner_element.nil? then #(Attr has an owner Element) { 
              return self.owner_element.lookup_namespace_uri( prefix )
            else
              return nil
            end
          else
            anc_node = self.parent_node
            loop do
              if anc_node.nil? or anc_node.node_type == ELEMENT_NODE then
                break
              end
              anc_node = anc_node.parent_node
            end
            if not anc_node.nil? then
              #if(Node has an ancestor Element) // EntityReferences may have to be skipped to get to it { 
              return anc_node.lookup_namespace_uri( prefix )
            else
              return nil
            end
        end
      end
      
      def is_default_namespace( namespace_uri )
        case self.node_type
          when ELEMENT_NODE then
            if self.prefix.nil? then
              return self.namespace_uri == namespace_uri
            end
            self.each_attr_node do |attr|
              #( Element has attributes and there is a valid DOM Level 2 default namespace declaration, i.e. 
              #Attr's localName == "xmlns" ) {
              if attr.local_name == "xmlns" then
                #/////////////////////////////////
                # 変更必要
                #/////////////////////////////////
                return attr[0] == namespace_uri
              end
            end
            anc_node = self.parent_node
            loop do
              if anc_node.nil? or anc_node.node_type == ELEMENT_NODE then
                break
              end
              anc_node = anc_node.parent_node
            end
            if not anc_node.nil? then #( Element has an ancestor Element ) // EntityReferences may have to be skipped to get to it {
              return anc_node.is_default_namespace( namespace_uri )
            else
              return false
            end
          when DOCUMENT_NODE then
            return self.document_element.is_default_namespace( namespace_uri )
          when ENTITY_NODE, NOTATION_NODE, DOCUMENT_TYPE_NODE, DOCUMENT_FRAGMENT_NODE then
            return false
          when ATTRIBUTE_NODE then
            if not self.owner_element.nil? then#( Attr has an owner Element ) {
              return self.owner_element.is_default_namespace( namespace_uri )
            else
              return false
            end
          else
            anc_node = self.parent_node
            loop do
              if anc_node.nil? or anc_node.node_type == ELEMENT_NODE then
                break
              end
              anc_node = anc_node.parent_node
            end
            if not anc_node.nil? then #( Element has an ancestor Element ) // EntityReferences may have to be skipped to get to it {
              return anc_node.is_default_namespace( namespace_uri )
            else
              return false
            end
        end
      end
      
    end
end
