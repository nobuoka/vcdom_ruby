# coding : utf-8

require "vcdom/node"
require "vcdom/element"

module VCDOM
  
  # This class implements {the interface Element of W3C DOM Element}[http://www.w3.org/TR/DOM-Level-3-Core/core.html#ID-745549614]. 
  # This class (ElementNS) supports a namespace URI, and the class Element doesn't support a namespace URI.
  class ElementNS < Element
    
    def initialize( doc, namespace_uri, prefix, local_name ) # :nodoc:
      super( doc, local_name )
      @namespace_uri = namespace_uri
      @prefix = prefix
    end
    
    def node_type
      ELEMENT_NODE
    end
    
    def tag_name
      if @prefix then
        "#{@prefix.to_s}:#{@local_name.to_s}"
      else
        @local_name.to_s()
      end
    end
    alias :node_name :tag_name
    
    def prefix
      @prefix.nil? ? nil : @prefix.to_s()
    end
    def local_name
      @local_name.to_s()
    end
    def namespace_uri
      @namespace_uri.nil? ? nil : @namespace_uri.to_s()
    end
    
    #def append_child( new_child )
    #  _append_child( new_child )
    #end
    
  end
  
end
