# coding : utf-8

require "vcdom/node"
require "vcdom/document"
require "vcdom/xpath/xpath_evaluator_mod"

module VCDOM
  module XPath
    
    class ::VCDOM::Document < ::VCDOM::Node
      include XPathEvaluatorMod
    end
    
  end
end
