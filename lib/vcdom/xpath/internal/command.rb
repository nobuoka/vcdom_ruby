# coding : utf-8

module VCDOM::XPath::Internal # :nodoc:
  
  class AbstractCommand # :nodoc:
    def is_value?;   false end
    def is_expr?;    false end
    def is_command?; true  end
    
    def to_s()
      "XPathCommand(#{command_type})"
    end
    
  end
  
  class AbstractOperationCommand < AbstractCommand # :nodoc:
    def initialize( operation_name )
      @operation_name = operation_name
    end
    attr_reader :operation_name
    
    def to_s()
      "XPathCommand(#{command_type}, #{operation_name})"
    end
  end
  
  class OperationUnaryCommand < AbstractOperationCommand # :nodoc:
    def command_type; :operation_unary end
  end
  
  class OperationBinaryCommand < AbstractOperationCommand # :nodoc:
    def command_type; :operation_binary end
  end
  
  @operation_unary_commands = {
    :"-@"  => OperationUnaryCommand.new( :"-@" ),
    :"+"   => OperationBinaryCommand.new( :"+" ),
    :"-"   => OperationBinaryCommand.new( :"-" ),
    :"*"   => OperationBinaryCommand.new( :"*" ),
    :"div" => OperationBinaryCommand.new( :"/" ),
    :"mod" => OperationBinaryCommand.new( :"%" ),
    :"="   => OperationBinaryCommand.new( :"==" ),
    :"!="  => OperationBinaryCommand.new( :"neq?" ),
    :"<"   => OperationBinaryCommand.new( :"<" ),
    :"<="  => OperationBinaryCommand.new( :"<=" ),
    :">"   => OperationBinaryCommand.new( :">" ),
    :">="  => OperationBinaryCommand.new( :">=" ),
    :"|"   => OperationBinaryCommand.new( :"|" ),
  }
  def self.get_operation_command( name )
    if @operation_unary_commands.include? name
      return @operation_unary_commands[name]
    else
      raise "NOT SUPPORTED"
    end
  end
  
  class ContextNodeCommand < AbstractCommand # :nodoc:
    def initialize(); end
    def command_type; :context_node end
    @@instance = self.new()
    def self.get_instance
      @@instance
    end
  end
  
  class RootNodeCommand < AbstractCommand # :nodoc:
    def initialize(); end
    def command_type; :root_node end
    @@instance = self.new()
    def self.get_instance
      @@instance
    end
  end
  
  class NodeSelectionCommand < AbstractCommand # :nodoc:
    def initialize( axis, node_type, node_ns_uri, node_name, pred_exprs )
      @axis = axis
      @node_type   = node_type
      @node_ns_uri = node_ns_uri
      @node_name   = node_name
      @pred_exprs  = pred_exprs
    end
    def command_type; :node_selection end
    attr_reader :axis
    attr_reader :node_type
    attr_reader :node_ns_uri
    attr_reader :node_name
    attr_reader :pred_exprs
  end
  
  class ExprEvalCommand < AbstractCommand # :nodoc:
    def initialize( expr )
      @expr = expr
    end
    attr_reader :expr
    def command_type; :expr_eval end
  end
  
  class FunctionCallCommand < AbstractCommand # :nodoc:
    EMPTY_ARGS = Array.new().freeze()
    def initialize( name, arg_exprs )
      @function_name = name
      @function_args = arg_exprs # nil ‚Ü‚½‚Í
    end
    attr_reader :function_name
    def function_args
      @function_args.nil? ? EMPTY_ARGS : @function_args
    end
    def command_type; :function_call end
  end
  
  class PredsEvalCommand < AbstractCommand # :nodoc:
    def initialize( exprs )
      @exprs = exprs
    end
    attr_reader :exprs
    def command_type; :preds_eval end
  end
  
end
