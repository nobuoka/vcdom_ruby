# coding : utf-8

module VCDOM::XPath # :nodoc:
  
  # A XPathNSResolver object permit prefix strings in the expression 
  # to be properly bound to namespaceURI strings. XPathEvaluator can 
  # construct an implementation of XPathNSResolver from a node, or 
  # the interface may be implemented by any application. 
  # 
  # == Way to create a XPathNSResolver object
  # 
  # If you want a XPathNSResolver object, please use XPathEvaluatorMod#create_expression.
  # The class Document includes the module XPathEvaluatorMod when you required "vcdom/xpath", so you can use this method as the following:
  # 
  #   require "vcdom"
  #   require "vcdom/xpath"
  #   # doc is a Document object
  #   resolver = doc.create_ns_resolver( node )
  # 
  class XPathNSResolver
    
    def initialize( ns_resolver ) # :nodoc:
      @ns_resolver = ns_resolver
    end
    
    # Look up the namespace URI associated to the given namespace prefix. 
    # The XPath evaluator must never call this with a null or empty argument, 
    # because the result of doing this is undefined.
    def lookup_namespace_uri( prefix )
      # TODO
      nil
    end
    
  end
  
end
