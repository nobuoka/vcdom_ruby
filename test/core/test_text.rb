# coding: UTF-8

require "test/unit"

require "vcdom"

class TestText < Test::Unit::TestCase
  
  @@dom_impl = VCDOM
  
  # 単純に Document オブジェクトから作り出した Text オブジェクトの値
  # Text ノードは node_value と data と text_content が同じ
  def test_node_value()
    doc = @@dom_impl.create_document( nil, "test" )
    data = "<attr_nameてすと>あいうえお&"
    text_node = doc.create_text_node( data )
    assert_equal( text_node.node_value, data )
    assert_equal( text_node.data, data )
    assert_equal( text_node.text_content, data )
  end
  
  # Text オブジェクトの node_name 属性は "#text"
  def test_name()
    doc = @@dom_impl.create_document( nil, "test" )
    data = "<attr_nameてすと>あいうえお&"
    text_node = doc.create_text_node( data )
    assert_equal( text_node.node_name, "#text" )
  end
  
end
