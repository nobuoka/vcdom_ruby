# coding : utf-8

require "vcdom/xpath/xpath_expression"
require "vcdom/xpath/xpath_ns_resolver"
require "vcdom/xpath/xpath_result"
require "vcdom/xpath/internal/parser"

module VCDOM::XPath
  
  module XPathEvaluatorMod
    
    def create_expression( expression, resolver )
      XPathExpression.new( Internal::Parser.new( expression, resolver ).parse() )
    end
    
    # Adapts any DOM node to resolve namespaces so that an XPath expression can be easily 
    # evaluated relative to the context of the node where it appeared within the document. 
    # This adapter works like the DOM Level 3 method lookupNamespaceURI on nodes in resolving 
    # the namespaceURI from a given prefix using the current information available in the 
    # node's hierarchy at the time lookupNamespaceURI is called. also correctly resolving 
    # the implicit xml prefix.
    def create_ns_resolver( node_resolver )
      XPathNSResolver.new( node_resolver )
    end
    
    def evaluate( expression, context_node, resolver, type, result = nil )
      return self.create_expression( expression, resolver ).evaluate( context_node, type, result )
    end
    
  end
  
end
