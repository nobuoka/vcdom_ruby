# coding : utf-8

require 'vcdom/document'
require 'vcdom/document_type'

# This Module object can be used as {the DOMImplementation object of W3C DOM Core}
# [http://www.w3.org/TR/DOM-Level-3-Core/core.html#ID-102161490].
module VCDOM
  
  # boolean            hasFeature(in DOMString feature, 
  #                                  in DOMString version);
  
  # DocumentType createDocumentType(in DOMString qualifiedName, 
  #                                          in DOMString publicId, 
  #                                          in DOMString systemId)
  #                                          raises(DOMException);
  def self.create_document_type( qname, public_id, system_id )
    doctype = DocumentType._new( qname, public_id, system_id )
    return doctype
  end
  
  # Creates a DOM Document object with its document element.
  # Now, the vcdom library doesn't support a XML Doctype, so the third argument +doctype+ has no effect.
  # @return [Document] 
  def self.create_document( namespace_uri, qualified_name, doctype = nil )
    doc = Document._new()
    if namespace_uri.nil? && qualified_name.nil? && doctype.nil?
      # do nothing
    else
      doc << doc.create_element_ns( namespace_uri, qualified_name )
    end
    return doc
  end
  
  #    // Introduced in DOM Level 3:
  #    DOMObject          getFeature(in DOMString feature, 
  #                                  in DOMString version);
  #  };
  
end
