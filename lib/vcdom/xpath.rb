# coding : utf-8

require "vcdom/node"
require "vcdom/document"
require "vcdom/xpath/xpath_evaluator_mod"

module VCDOM
  
  module XPath
    
  end
  
  class Document < VCDOM::Node
    include VCDOM::XPath::XPathEvaluatorMod
  end
  
end
