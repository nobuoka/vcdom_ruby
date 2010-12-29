# coding: UTF-8

require "test/unit"

require "vcdom/xml_ls"

class TestParsing < Test::Unit::TestCase
  
  @@ls_impl = VCDOM::XMLLS
  
  def test_of_one_element_xml_string_parsing
    parser = @@ls_impl.create_ls_parser( :mode_asynchronous, nil )
    input  = @@ls_impl.create_ls_input()
    input.string_data = "<empty-element/>"
    doc = parser.parse( input )
    root_elem = doc.first_child
    assert_equal( "empty-element", root_elem.node_name )
    assert( root_elem.equal? doc.document_element )
    assert( root_elem.equal? doc.last_child )
    assert( root_elem.parent_node.equal? doc )
  end
  
end
