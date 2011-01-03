# coding : utf-8

module VCDOM::XPath
  
  class XPathException < Exception
    
    # If the expression has a syntax error or otherwise is not a legal expression 
    # according to the rules of the specific XPathEvaluator or contains specialized 
    # extension functions or variables not supported by this implementation.
    INVALID_EXPRESSION_ERR = :invalid_expression_err
    # If the expression cannot be converted to return the specified type.
    TYPE_ERR               = :type_err
    
    attr_reader :type
    
    def initialize( type, msg )
      super msg
      @type = type
    end
    
  end
  
end
