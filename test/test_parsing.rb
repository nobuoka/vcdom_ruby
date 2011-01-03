# coding: UTF-8

require "test/unit"

require "vcdom/xml_ls"

class TestParsing < Test::Unit::TestCase
  
  @@ls_impl = VCDOM::XMLLS
  
  def test_of_parsing_one_element_xml_string()
    parser = @@ls_impl.create_ls_parser( :mode_asynchronous, nil )
    input  = @@ls_impl.create_ls_input()
    input.string_data = "<empty-element/>"
    doc = parser.parse( input )
    root_elem = doc.document_element
    assert_equal( "empty-element", root_elem.node_name )
    assert( root_elem.equal? doc.first_child )
    assert( root_elem.equal? doc.last_child  )
    assert( root_elem.parent_node.equal? doc )
  end
  
  def test_of_parsing_text_node()
    parser = @@ls_impl.create_ls_parser( :mode_asynchronous, nil )
    input  = @@ls_impl.create_ls_input()
    input.string_data = "<element>テキストノードです\n改行</element>"
    doc = parser.parse( input )
    root_elem = doc.document_element
    assert_equal( "テキストノードです\n改行", root_elem.first_child.node_value )
  end
  
  def test_of_parsing_text_node_within_predefined_char_ref()
    parser = @@ls_impl.create_ls_parser( :mode_asynchronous, nil )
    input  = @@ls_impl.create_ls_input()
    input.string_data = "<element>テキストノードです&lt;うん&gt;私&amp;あなた&quot;&apos;&amp;</element>"
    doc = parser.parse( input )
    root_elem = doc.document_element
    assert_equal( "テキストノードです<うん>私&あなた\"'&", root_elem.first_child.node_value )
  end
  
end
