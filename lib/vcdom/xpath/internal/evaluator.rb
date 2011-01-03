# coding : utf-8

require "vcdom/xpath/internal/value"

module VCDOM::XPath::Internal # :nodoc:
  
  class Evaluator # :nodoc:
    
    def context_node;     @context_node_stack[-1] end
    def context_size;     @context_size_stack[-1] end
    def context_position; @context_pos_stack[-1]  end
    
    def change_context_node_and_position( context_node, position, &block )
      @context_node_stack.push context_node
      @context_pos_stack.push position
      block.call
      @context_pos_stack.pop
      @context_node_stack.pop
    end
    def change_context_size( size, &block )
      @context_size_stack.push size
      block.call
      @context_size_stack.pop
    end
    
    def evaluate_expr( expr )
      # TODO
      case expr.expr_type
      when :or_expr
        return evaluate_or_expr( expr )
      when :and_expr
        return evaluate_and_expr( expr )
      when :equality_expr
        return evaluate_equality_expr( expr )
      else
        raise "INTERNAL ERROR"
      end
    end
    
    def evaluate_or_expr( expr )
      # TODO
      raise "NOT STILL BE SUPPORTED"
    end
    
    def evaluate_and_expr( expr )
      # TODO
      raise "NOT STILL BE SUPPORTED"
    end
    
    def evaluate_equality_expr( expr )
      # TODO
      val_stack = Array.new()
      expr.each do |e|
        if e.is_value? or e.is_expr? then
          val_stack.push e
        else
          case e.command_type
          when :operation_unary
            operand = val_stack.pop
            val_stack.push operand.send( e.operation_name )
          when :operation_binary
            operand2 = val_stack.pop
            operand1 = val_stack.pop
            val_stack.push operand1.send( e.operation_name, operand2 )
          when :expr_eval
            val_stack.push evaluate_expr( e.expr )
          when :function_call
            args = Array.new()
            e.function_args.each do |arg_expr|
              args << evaluate_expr( arg_expr )
            end
            val_stack.push( call_function( e.function_name, args ) )
          when :node_selection
            target = val_stack.pop
            val_stack.push evaluate_node_selection( target, e )
          when :preds_eval
            target = val_stack.pop
            val_stack.push evaluate_preds( target, e.exprs )
          when :context_node
            val_stack.push create_node_set_value( context_node )
          when :root_node
            # TODO : context_node.class::DOCUMENT_NODE を書き換え
            root_node = ( context_node.node_type == context_node.class::DOCUMENT_NODE ? context_node : context_node.owner_document )
            val_stack.push create_node_set_value( root_node )
          else
            raise "NOT SUPPORTED"
          end
        end
      end
      raise "INTERNAL ERROR" if val_stack.length != 1
      return val_stack.pop
    end
    
    def call_function( name, args )
      args.each do |a|
        raise "USER ERROR" unless a.is_value?
      end
      send( "_xpath_#{name}".intern, *args )
    end
    
    NODE_SELECTION_BY_AXIS_PROCS = {
      :'self'  => lambda { |c_node, new_nodes|
        new_nodes << c_node
      },
      :'child' => lambda { |c_node, new_nodes|
        c_node.each_child_node { |n| new_nodes << n }
      },
      :'parent' => lambda { |c_node, new_nodes|
        if c_node.node_type == c_node.class::ATTRIBUTE_NODE then # TODO
          new_nodes << c_node.owner_element if c_node.owner_element
        elsif c_node.node_type == :xpath_namespace_node then
          raise "NOT SUPPORTED"
        else
          new_nodes << c_node.parent_node if c_node.parent_node
        end
      },
      :'descendant' => lambda { |c_node, new_nodes|
        node = c_node.first_child
        if node then
          while not node.equal? c_node do
            new_nodes << node
            if node.first_child then
              node = node.first_child
            elsif node.next_sibling
              node = node.next_sibling
            else
              # TODO
              node = node.parent_node
              while not node.equal? c_node do
                if node.next_sibling then
                  node = node.next_sibling
                  break
                else
                  node = node.parent_node
                end
              end
            end
          end
        end
      },
      :'descendant-or-self' => lambda { |c_node, new_nodes|
        new_nodes << c_node
        NODE_SELECTION_BY_AXIS_PROCS[:"descendant"].call( c_node, new_nodes )
      },
      :'ancestor' => lambda { |c_node, new_nodes|
        node = c_node.parent_node
        while node do
          new_nodes << node
          node = node.parent_node
        end
      },
      :'ancestor-or-self' => lambda { |c_node, new_nodes|
        new_nodes << c_node
        NODE_SELECTION_BY_AXIS_PROCS[:"ancestor"].call( c_node, new_nodes )
      },
      :'following' => lambda { |c_node, new_nodes|
        raise "NOT SUPPORTED"
      },
      :'following-sibling' => lambda { |c_node, new_nodes|
        raise "NOT SUPPORTED"
      },
      :'preceding' => lambda { |c_node, new_nodes|
        raise "NOT SUPPORTED"
      },
      :'preceding-sibling' => lambda { |c_node, new_nodes|
        raise "NOT SUPPORTED"
      },
      :'attribute' => lambda { |c_node, new_nodes|
        if c_node.attributes then
          c_node.attributes.each do |n|
            if n.namespace_uri != "http://www.w3.org/2000/xmlns/" then
              new_nodes << n
            end
          end
        end
      },
      :'namespace' => lambda { |c_node, new_nodes|
        raise "NOT SUPPORTED"
      },
    }
    
    def evaluate_node_selection( nodes, cmd )
      # cmd.pred_exprs は nil の可能性あり
      # cmd.node_test_name も nil の可能性あり
      # cmd.node_test_type は :any, :, :processing-instruction など
      new_nodes = Array.new()
      nodes.each do |c_node|
        c_nodes = Array.new()
        # TODO : 軸によって対象となるノードを集める
        if ( node_selection_by_axis_proc = NODE_SELECTION_BY_AXIS_PROCS[ cmd.axis ] ).nil? then
          raise "invalid axis [#{cmd.axis}]"
        end
        node_selection_by_axis_proc.call( c_node, c_nodes )
        # type, name, ns url によって絞り込む
        c_nodes = evaluate_node_selection_sub( c_nodes, cmd )
        # TODO : 軸によって順序を変更？
        if cmd.pred_exprs then
          cmd.pred_exprs.each do |expr|
            c_nodes = evaluate_pred_internal( c_nodes, expr )
          end
        end
        new_nodes.concat c_nodes
      end
      new_nodes.uniq!
      create_node_set_value( *new_nodes )
    end
    
    def evaluate_node_selection_sub( nodes, cmd )
      # node_type での絞り込み
      case cmd.node_type
      when :node
        # do nothing
      when :named_node
        case cmd.axis
        when :attribute
          raise "NOT SUPPORTED"
        when :namespace
          raise "NOT SUPPORTED"
        else
          expected_type = VCDOM::Node::ELEMENT_NODE # TODO : change
        end
        nodes = nodes.inject( Array.new() ) do |arr,n|
          arr << n if n.node_type == expected_type
        end
      else
        raise "NOT SUPPORTED"
      end
      new_nodes = Array.new()
      # node_ns_url での絞り込み      # node_name での絞り込み
      if cmd.node_ns_uri.nil? then #and cmd.node_name.nil? then
        if cmd.node_name.nil? then
          new_nodes = nodes
        else
          nodes.each do |n|
            new_nodes << n if n.namespace_uri.nil? and ( n.local_name || n.node_name ) == cmd.node_name.to_s
          end
        end
      else
        nodes.each do |n|
          new_nodes << n if n.namespace_uri == cmd.node_ns_uri.to_s and n.local_name == cmd.node_name.to_s
        end
      end
      new_nodes
    end
    
    def evaluate_preds( nodes, exprs )
      raise "User Error?" if nodes.value_type != :node_set
      # TODO
      nodes.sort()
      nodes = nodes.value
      exprs.each do |expr|
        nodes = evaluate_pred_internal( nodes, expr )
      end
      create_node_set_value( *nodes )
    end
    
    # evaluate_preds および evaluate_node_selection から呼び出される
    def evaluate_pred_internal( nodes, expr )
      new_nodes = Array.new()
      change_context_size( nodes.length ) do
        nodes.each_with_index do |node,i|
          change_context_node_and_position( node, i+1 ) do
            res = evaluate_expr( expr )
            if ( res.value_type == :number and res.value == context_position ) or
                  ( res.value_type != :number and res.to_boolean_value.value ) then
              new_nodes << node
            end
          end
        end
      end
      new_nodes
    end
    
    def create_number_value( num )
      NumberValue.new( num.to_f )
    end
    def create_boolean_value( bool )
      bool ? BooleanValue::TRUE : BooleanValue::FALSE
    end
    def create_string_value( str )
      StringValue.new( str )
    end
    def create_node_set_value( *nodes )
      NodeSetValue.new( *nodes )
    end
    
    def initialize( context_node )
      ( @context_node_stack = Array.new() ).push context_node
      ( @context_size_stack = Array.new() ).push 1
      ( @context_pos_stack  = Array.new() ).push 1
    end
    
    def self.set_xpath_function( name, func )
      define_method "_xpath_#{name}".intern, func
    end
    
  end
  
  # setting xpath functions
  Evaluator.set_xpath_function( :position, lambda { || create_number_value( context_position ) } )
  Evaluator.set_xpath_function( :true,     lambda { || create_boolean_value( true ) } )
  Evaluator.set_xpath_function( :false,    lambda { || create_boolean_value( false ) } )
  Evaluator.set_xpath_function( :string,   lambda { |*args|
        raise "ERROR" if args.length > 2
        ( args.length == 0 ? NodeSetValue.new( context_node ) : args[0] ).to_string_value } )
  
end
