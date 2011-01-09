# coding: UTF-8

require "test/unit"

require "vcdom"

class TestElement < Test::Unit::TestCase
  
  @@dom_impl = VCDOM
  
  # 単純に Document オブジェクトから作り出した Attr オブジェクトの名前のテスト
  def test_element_name()
    doc = @@dom_impl.create_document( nil, "test" )
    name = "attr_nameてすと"
    elem = doc.create_element( name )
    assert_equal( elem.tag_name, name )
    assert_equal( elem.node_name, name )
  end
  
  # 単純に Document オブジェクトから作り出した Attr オブジェクトの名前のテスト
  def test_text_content_setting()
    doc = @@dom_impl.create_document( nil, "test" )
    name = "attr_nameてすと"
    elem = doc.create_element( name )
    text_str = "これはてすとです><&あいうえお"
    elem.text_content = text_str
    assert_equal( elem.text_content, text_str )
    assert_equal( elem.child_nodes.length, 1 )
    assert_equal( elem.first_child.node_type, :text_node )
    assert_equal( elem.first_child.data, text_str )
  end
  
end
