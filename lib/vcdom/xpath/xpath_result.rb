# coding : utf-8

require "vcdom/xpath/xpath_exception"

module VCDOM::XPath
  
  # This class implements {the interface XPathResult of W3C DOM XPath}[http://www.w3.org/TR/DOM-Level-3-XPath/xpath.html#XPathResult]. 
  # 
  # == When you get a XPathResult object
  # 
  # You get a XPathResult object as return value of XPathExpression#evaluate or XPathEvaluatorMod#evaluate.
  # 
  #   require "vcdom"
  #   require "vcdom/xpath"
  #   
  #   # doc is a Document object
  #   expr   = doc.create_expression( "1 + 2 + 3", nil )
  #   result = expr.evaluate( node, :number_type )
  #   
  #   result.number_value #=> 6.0
  # 
  class XPathResult
    
    ANY_TYPE                       = :any_type
    NUMBER_TYPE                    = :number_type
    STRING_TYPE                    = :string_type
    BOOLEAN_TYPE                   = :boolean_type
    UNORDERED_NODE_ITERATOR_TYPE   = :unordered_node_iterator_type
    ORDERED_NODE_ITERATOR_TYPE     = :ordered_node_iterator_type
    UNORDERED_NODE_SNAPSHOT_TYPE   = :unordered_node_snapshot_type
    ORDERED_NODE_SNAPSHOT_TYPE     = :ordered_node_snapshot_type
    ANY_UNORDERED_NODE_TYPE        = :any_unordered_node_type
    FIRST_ORDERED_NODE_TYPE        = :first_ordered_node_type
    
    def result_type
      raise "INTERNAL ERROR"
    end
    # Signifies that the iterator has become invalid. True if resultType is UNORDERED_NODE_ITERATOR_TYPE 
    # or ORDERED_NODE_ITERATOR_TYPE and the document has been modified since this result was returned.
    def invalid_iterator_state
      false
    end
    def snapshot_length
      raise XPathException.new( XPathException::TYPE_ERR, 
            "result type is not UNORDERED_NODE_SNAPSHOT_TYPE or ORDERED_NODE_SNAPSHOT_TYPE" )
    end
    
    # raises(XPathException) on retrieval
    def number_value
      raise XPathException.new( XPathException::TYPE_ERR, "result type is not NUMBER_TYPE" )
    end
    def string_value
      raise XPathException.new( XPathException::TYPE_ERR, "result type is not STRING_TYPE" )
    end
    def boolean_value
      raise XPathException.new( XPathException::TYPE_ERR, "result type is not STRING_TYPE" )
    end
    def single_node_value
      raise XPathException.new( XPathException::TYPE_ERR, 
            "result type is not ANY_UNORDERED_NODE_TYPE or FIRST_ORDERED_NODE_TYPE" )
    end
    def snapshot_item( index )
      raise XPathException.new( XPathException::TYPE_ERR,
            "result type is not UNORDERED_NODE_SNAPSHOT_TYPE or ORDERED_NODE_SNAPSHOT_TYPE" )
    end
    def iterate_next()
      raise XPathException.new( XPathException::TYPE_ERR,
            "result type is not UNORDERED_NODE_ITERATOR_TYPE or ORDERED_NODE_ITERATOR_TYPE" )
    end
    
    ##
    # @private
    def initialize( value ) # :nodoc:
      @value = value
    end
    
  end
  
end

class VCDOM::XPath::XPathResult
  
  # This class is subclass of XPathResult.
  # This exists to represent a number type result of XPath expression.
  class ResultNumber < self
    def result_type;  NUMBER_TYPE end
    def number_value; @value      end
  end
  class ResultString < self
    def result_type;  STRING_TYPE end
    def string_value; @value      end
  end
  class ResultBoolean < self
    def result_type;  BOOLEAN_TYPE end
    def boolean_value; @value      end
    TRUE  = self.new( true )
    FALSE = self.new( false )
  end
  class ResultSingleNode < self
    def initialize( node, type ) # :nodoc:
      super( node )
      @type = type
    end
    def result_type; @type end
    def single_node_value; @value end
  end
  class ResultNodesSnapshot < self
    def initialize( nodes, type ) # :nodoc:
      super( nodes )
      @type = type
    end
    def result_type; @type end
    def snapshot_length
      @value.length
    end
    def snapshot_item( index )
      @value[index]
    end
    alias :[] :snapshot_item
  end
  
end
