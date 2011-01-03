# coding: UTF-8

require "test/unit"

require "vcdom/xpath"
require "vcdom/xpath/xpath_expression"
require "vcdom/xpath/xpath_result"
require "vcdom/xpath/internal/value"
require "vcdom/xpath/internal/expr"
require "vcdom/xpath/internal/command"

class TestXPath < Test::Unit::TestCase
  
  @@ls_impl = VCDOM::XMLLS
  
  require "vcdom/document"
  @@doc = VCDOM::Document._new()
  elem = @@doc.append_child @@doc.create_element( "test" )
  elem << @@doc.create_element( "test-child1" )
  elem << @@doc.create_element( "test-child2" )
  elem << @@doc.create_element( "test-child3" )
  #doc.create_expression(nil,nil)
  
  def test_creating_xpath_expression()
    xpath_expr = @@doc.create_expression( "//test-child1/.././test-child1", nil )
    res = xpath_expr.evaluate( @@doc, :any_unordered_node_type )
    assert_equal @@doc.document_element.first_child, res.single_node_value
  end
  
  def test_creating_xpath_expression_snapshot()
    res = @@doc.evaluate( "/*/child::*[2]", @@doc, nil, :unordered_node_snapshot_type )
    assert_equal :unordered_node_snapshot_type, res.result_type
    assert_equal 1, res.snapshot_length
    assert_equal @@doc.first_child.first_child.next_sibling, res.snapshot_item( 0 )
  end
  
  ##
  # 関数呼び出しのテスト
  def test_of_evaluating_function_call()
    res_type = :number_type
    res = evaluate_equality_expr( res_type, res_type, 1.0 ) do |expr|
      expr << VCDOM::XPath::Internal::FunctionCallCommand.new( :position, nil )
    end
  end
  
  ##
  # 数値, リテラル, 真偽値単体を返す式のチェック
  # 結果は数値として受け取る
  def test_of_evaluating_expr_having_only_one_value_number()
    res_type = :number_type
    res = evaluate_equality_expr( res_type, res_type, 10.0 ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( 10 )
    end
  end
  
  ##
  # 数値, リテラル, 真偽値単体を返す式のチェック
  # 結果は文字列として受け取る
  def test_of_evaluating_expr_having_only_one_value_string()
    res_type = :string_type
    res = evaluate_equality_expr( res_type, res_type, "10" ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( 10 )
    end
    res = evaluate_equality_expr( res_type, res_type, "100.5" ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( 100.5 )
    end
    res = evaluate_equality_expr( res_type, res_type, "てすと" ) do |expr|
      expr << VCDOM::XPath::Internal::StringValue.new( "てすと" )
    end
    res = evaluate_equality_expr( res_type, res_type, "true" ) do |expr|
      expr << VCDOM::XPath::Internal::FunctionCallCommand.new( :true, nil )
    end
    res = evaluate_equality_expr( res_type, res_type, "false" ) do |expr|
      expr << VCDOM::XPath::Internal::FunctionCallCommand.new( :false, nil )
    end
  end
  
  ##
  # 数値, リテラル, 真偽値単体を返す式のチェック
  # 結果は真偽値として受け取る
  def test_of_evaluating_expr_having_only_one_value_boolean()
    res_type = :boolean_type
    res = evaluate_equality_expr( res_type, res_type, true ) do |expr|
      expr << VCDOM::XPath::Internal::FunctionCallCommand.new( :true, nil )
    end
  end
  
  ##
  # 算術演算のテスト
  def test_operation_of_numbers()
    res_type = :number_type
    res = evaluate_equality_expr( res_type, res_type, 5.0 ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( 5 )
      expr << VCDOM::XPath::Internal::NumberValue.new( 5 )
      expr << VCDOM::XPath::Internal.get_operation_command( :"+" )
      expr << VCDOM::XPath::Internal::NumberValue.new( 10 )
      expr << VCDOM::XPath::Internal.get_operation_command( :"-@" )
      expr << VCDOM::XPath::Internal.get_operation_command( :"+" )
      expr << VCDOM::XPath::Internal::NumberValue.new( 1 )
      expr << VCDOM::XPath::Internal.get_operation_command( :"-" )
      expr << VCDOM::XPath::Internal::NumberValue.new( 2 )
      expr << VCDOM::XPath::Internal.get_operation_command( :"div" )
      expr << VCDOM::XPath::Internal::NumberValue.new( -10 )
      expr << VCDOM::XPath::Internal.get_operation_command( :"*" )
    end
  end
  def test_operation_of_numbers_mod()
    res_type = :number_type
    res = evaluate_equality_expr( res_type, res_type, 1.0 ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( 5 )
      expr << VCDOM::XPath::Internal::NumberValue.new( 2 )
      expr << VCDOM::XPath::Internal.get_operation_command( :"mod" )
    end
    res = evaluate_equality_expr( res_type, res_type, 1.0 ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( 5 )
      expr << VCDOM::XPath::Internal::NumberValue.new( -2 )
      expr << VCDOM::XPath::Internal.get_operation_command( :"mod" )
    end
    res = evaluate_equality_expr( res_type, res_type, -1.0 ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( -5 )
      expr << VCDOM::XPath::Internal::NumberValue.new( 2 )
      expr << VCDOM::XPath::Internal.get_operation_command( :"mod" )
    end
    res = evaluate_equality_expr( res_type, res_type, -1.0 ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( -5 )
      expr << VCDOM::XPath::Internal::NumberValue.new( -2 )
      expr << VCDOM::XPath::Internal.get_operation_command( :"mod" )
    end
  end
  
  ##
  # 文字列を数値に変換するテスト
  def test_conversion_str_to_num()
    res_type = :number_type
    res = evaluate_equality_expr( res_type, res_type, 105.0 ) do |expr|
      expr << VCDOM::XPath::Internal::StringValue.new( "105.0" )
    end
    res = evaluate_equality_expr( res_type, res_type, 12.0 ) do |expr|
      expr << VCDOM::XPath::Internal::StringValue.new( "12." )
    end
    res = evaluate_equality_expr( res_type, res_type, -0.5 ) do |expr|
      expr << VCDOM::XPath::Internal::StringValue.new( "-.500000" )
    end
    res = evaluate_equality_expr( res_type, res_type, lambda { |v| v.nan? } ) do |expr|
      expr << VCDOM::XPath::Internal::StringValue.new( "45aa" )
    end
  end
  
  ##
  # Boolean に変換するテスト
  def test_conversion_num_to_bool()
    res_type = :boolean_type
    res = evaluate_equality_expr( res_type, res_type, true ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( 105.0 )
    end
    res = evaluate_equality_expr( res_type, res_type, false ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( 0.0 )
    end
  end
  def test_conversion_str_to_bool()
    res_type = :boolean_type
    res = evaluate_equality_expr( res_type, res_type, true ) do |expr|
      expr << VCDOM::XPath::Internal::StringValue.new( "aaaa" )
    end
    res = evaluate_equality_expr( res_type, res_type, false ) do |expr|
      expr << VCDOM::XPath::Internal::StringValue.new( "" )
    end
  end
  
  ##
  # 比較演算テスト
  def test_operation_of_relation()
    res_type = :boolean_type
    res = evaluate_equality_expr( res_type, res_type, false ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( 5 )
      expr << VCDOM::XPath::Internal::NumberValue.new( 5 )
      expr << VCDOM::XPath::Internal.get_operation_command( :">" )
    end
    res = evaluate_equality_expr( res_type, res_type, true ) do |expr|
      expr << VCDOM::XPath::Internal::NumberValue.new( "5" )
      expr << VCDOM::XPath::Internal::NumberValue.new( 100 )
      expr << VCDOM::XPath::Internal.get_operation_command( :"<" )
    end
  end
  
  ##
  # Node を取得するテスト
  def test_root_node()
    res_type = :any_unordered_node_type
    res = evaluate_equality_expr( res_type, res_type, @@doc ) do |expr|
      expr << VCDOM::XPath::Internal::RootNodeCommand.new()
    end
  end
  
  ##
  # Node を選択するテスト
  def test_node_selection()
    res_type = :any_unordered_node_type
    res = evaluate_equality_expr( res_type, res_type, @@doc.document_element ) do |expr|
      expr << VCDOM::XPath::Internal::RootNodeCommand.new()
      expr << VCDOM::XPath::Internal::NodeSelectionCommand.new( :child, :named_node, nil, nil, nil )
    end
  end
  
  ##
  # union 演算子のテスト
  def test_operator_union()
    res_type = :any_unordered_node_type
    res = evaluate_equality_expr( res_type, res_type, @@doc ) do |expr|
      expr << VCDOM::XPath::Internal::RootNodeCommand.new()
      expr << VCDOM::XPath::Internal::RootNodeCommand.new()
      expr << VCDOM::XPath::Internal.get_operation_command( :"|" )
    end
  end
  
  ##
  # Predicate テスト
  def test_predicate()
    res_type = :any_unordered_node_type
    res = evaluate_equality_expr( res_type, res_type, @@doc ) do |expr|
      expr << VCDOM::XPath::Internal::RootNodeCommand.new()
      expr << VCDOM::XPath::Internal::PredsEvalCommand.new( [
        VCDOM::XPath::Internal::EqualityExpr.new(
          VCDOM::XPath::Internal::NumberValue.new( 1.0 )
        )
      ] )
    end
    res_type = :any_unordered_node_type
    res = evaluate_equality_expr( res_type, res_type, nil ) do |expr|
      expr << VCDOM::XPath::Internal::RootNodeCommand.new()
      expr << VCDOM::XPath::Internal::PredsEvalCommand.new( [
        VCDOM::XPath::Internal::EqualityExpr.new(
          VCDOM::XPath::Internal::NumberValue.new( 2.0 )
        )
      ] )
    end
  end
  
  ##
  # equality expr のテストを補助するための関数
  def evaluate_equality_expr( res_type, expected_type, expected_val )
    internal_expr = VCDOM::XPath::Internal::EqualityExpr.new()
    yield( internal_expr )
    expr = VCDOM::XPath::XPathExpression.new( internal_expr )
    res = expr.evaluate( @@doc, res_type, nil )
    assert_equal( expected_type, res.result_type )
    case expected_type
    when :number_type
      val = res.number_value
    when :string_type
      val = res.string_value
    when :boolean_type
      val = res.boolean_value
    when :any_unordered_node_type, :first_ordered_node_type
      val = res.single_node_value
    else
      raise "ERROR"
    end
    if expected_val.is_a? Proc then
      assert expected_val.call( val )
    else
      assert_equal( expected_val, val )
    end
  end
  
end
