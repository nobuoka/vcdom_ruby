# coding : utf-8

module VCDOM::XPath
  
  # This class implements {the interface XPathExpression of W3C DOM XPath}[http://www.w3.org/TR/DOM-Level-3-XPath/xpath.html#XPathExpression]. 
  # 
  # == Way to create a XPathExpression object
  # When you want a XPathExpression object, please use XPathEvaluatorMod#create_expression method.
  # The class Document implements the module XPathEvaluatorMod when you required "vcdom/xpath", so you can use this method as the following:
  # 
  #   require "vcdom"
  #   require "vcdom/xpath"
  #   # doc is a Document object
  #   expr = doc.create_expression( "/test/abc", nil )
  # 
  class XPathExpression
    
    #require "vcdom/xpath/internal/tokenizer"
    #require "vcdom/xpath/internal/parser"
    require "vcdom/xpath/xpath_result"
    require "vcdom/xpath/internal/evaluator"
    
    def initialize( expr ) # :nodoc:
      @expr = expr
    end
    
    # Evaluates the XPath expression.
    # 
    # Usage:
    # 
    #   # expr is a XPathExpression object, and elem is an Element object.
    #   result   = expr.evaluate( elem, :first_ordered_node_type )
    #   res_node = result.single_node_value
    def evaluate( context_node, type, result = nil )
      res = Internal::Evaluator.new( context_node ).evaluate_expr( @expr )
      case type
      when :any_type
        case res.value_type
        when :number
          type = :number_type
        when :string
          type = :string_type
        when :boolean
          type = :boolean_type
        when :node_set
          type = :unordered_node_iterator_type
        else
          raise "INTERNAL ERROR"
        end
      when :number_type
        res = res.to_number_value if res.value_type != :number
        xpath_result = XPathResult::ResultNumber.new( res.value )
      when :string_type
        res = res.to_string_value if res.value_type != :string
        xpath_result = XPathResult::ResultString.new( res.value )
      when :boolean_type
        res = res.to_boolean_value if res.value_type != :boolean
        xpath_result = XPathResult::ResultBoolean.new( res.value )
      when :first_ordered_node_type
        res.sort
        xpath_result = XPathResult::ResultSingleNode.new( res.value[0], :first_ordered_node_type )
      when :any_unordered_node_type
        xpath_result = XPathResult::ResultSingleNode.new( res.value[0], :any_unordered_node_type )
      when :ordered_node_snapshot_type
        res.sort
        xpath_result = XPathResult::ResultNodesSnapshot.new( res.value, :ordered_node_snapshot_type )
      when :unordered_node_snapshot_type
        xpath_result = XPathResult::ResultNodesSnapshot.new( res.value, :unordered_node_snapshot_type )
      when :ordered_node_iterator_type, :unordered_node_iterator_type
        raise "not still be supported" # TODO
      else
        raise "USER ERROR"
      end
      return xpath_result
    end
    
  end
  
end
