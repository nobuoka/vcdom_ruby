# coding : utf-8

require "vcdom/node"
require "vcdom/parent"
require "vcdom/element"
require "vcdom/element_ns"
require "vcdom/attr"
require "vcdom/attr_ns"
require "vcdom/text"

module VCDOM
class DocumentType < Node
  
  include Child # 子ノードになりえるノードは include する
  
  def initialize( name, public_id, system_id ) # :nodoc:
    super( nil )
    @name = name
    @public_id = public_id
    @system_id = system_id
  end
  
  def node_type
    DOCUMENT_TYPE_NODE
  end
  
  def name
    @name
  end
  
  def public_id
    @public_id
  end
  
  def system_id
    @system_id
  end
  
      #readonly attribute DOMString       name;
      #readonly attribute NamedNodeMap    entities;
      #readonly attribute NamedNodeMap    notations;
      #// Introduced in DOM Level 2:
      #readonly attribute DOMString       publicId;
      #// Introduced in DOM Level 2:
      #readonly attribute DOMString       systemId;
      #// Introduced in DOM Level 2:
      #readonly attribute DOMString       internalSubset;
      
end
end
