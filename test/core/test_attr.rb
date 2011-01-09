# coding: UTF-8

require "test/unit"

require "vcdom"

class TestAttr < Test::Unit::TestCase
  
  @@dom_impl = VCDOM
  
  # 単純に Document オブジェクトから作り出した Attr オブジェクトの名前のテスト
  def test_node_name()
    doc = @@dom_impl.create_document( nil, "test" )
    name = "attr_nameてすと"
    attr = doc.create_attribute( name )
    assert_equal( attr.name, name )
    assert_equal( attr.node_name, name )
  end
  
end
