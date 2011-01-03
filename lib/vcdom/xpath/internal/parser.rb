# coding : utf-8

require "strscan"

require "vcdom/xpath/xpath_expression"
require "vcdom/xpath/xpath_result"
require "vcdom/xpath/internal/value"
require "vcdom/xpath/internal/expr"
require "vcdom/xpath/internal/command"

module VCDOM::XPath::Internal # :nodoc:
  
  class Parser # :nodoc: all
    
    regexp_str_creating_proc = lambda { |*args|
      args.length == 1 ? [ args[0] ].pack( "U1" ) : [ args[0], 0x2D, args[1] ].pack( "U3" )
    }
    
    xml_name_start_char = [
      [ 0xC0, 0xD6 ],
      [ 0xD8, 0xF6 ],
      [ 0xF8, 0x2FF ],
      [ 0x370, 0x37D ],
      [ 0x37F, 0x1FFF ],
      [ 0x200C, 0x200D ],
      [ 0x2070, 0x218F ],
      [ 0x2C00, 0x2FEF ],
      [ 0x3001, 0xD7FF ],
      [ 0xF900, 0xFDCF ],
      [ 0xFDF0, 0xFFFD ],
      [ 0x10000, 0xEFFFF ]
    ].inject( String.new( "_a-zA-Z" ) ) do |s,pair|
      s << regexp_str_creating_proc.call( *pair )
    end
    
    xml_name_char = [
      [ 0xB7 ],
      [ 0x0300, 0x036F ],
      [ 0x203F, 0x2040 ]
    ].inject( String.new( xml_name_start_char + "\\-\\.\\d" ) ) do |s,pair|
      s << regexp_str_creating_proc.call( *pair )
    end
    
    xml_nc_name    = "[#{xml_name_start_char}][#{xml_name_char}]*"
    xml_q_name     = "(?:#{xml_nc_name}:)?#{xml_nc_name}"
    xpath_literal  = "\"[^\"]*\"|'[^']*'"
    xpath_operator = "\\/?\\/|\\||\\+|\\-|=|\\!=|<=?|>=?"
    xpath_sign     = "\\(|\\)|\\[|\\]|\\.\\.?|@|,|::"
    xpath_number   = "\\d+(?:\\.\\d*)?|\\.\\d+"
    #xpath_varref   = "\\$#{xml_q_name}"  # varref は anyname と結合
    xpath_anyname  = "(?:#{xml_nc_name}:)?\\*|\\$?#{xml_q_name}"
    #XML_NC_NAME_REGEXP = /#{xml_nc_name}/u
    #XML_Q_NAME_REGEXP  = /(?:#{xml_nc_name}:)?#{xml_nc_name}/u
    
    xpath_token = xpath_literal + "|" + xpath_number + "|" + xpath_anyname + "|" + xpath_operator + "|" + xpath_sign
    
    XML_Q_NAME = /#{xml_q_name}/u
    XPATH_TOKEN_REGEXP = /#{xpath_token}/u
    XPATH_WHITE_SPACE_REGEXP = /[\x20\x0A\x0D\x09]+/u
    
    #def next_token()
    #  @scanner.skip XPATH_WHITE_SPACE_REGEXP
    #  if ( token = @scanner.scan XPATH_TOKEN_REGEXP ).nil? then
    #    raise "Invalid XPath expression" unless @scanner.eos?
    #  end
    #  token
    #end
    
    class XPathStringScanner < StringScanner
      XPATH_WHITE_SPACE_REGEXP = /[\x20\x0A\x0D\x09]+/u
      def scan( regexp )
        skip XPATH_WHITE_SPACE_REGEXP
        super( regexp )
      end
      def check( regexp )
        skip XPATH_WHITE_SPACE_REGEXP
        super( regexp )
      end
    end
    
    def initialize( xpath_str, ns_resolver )
      @scanner = XPathStringScanner.new( xpath_str )
      @ns_resolver = ns_resolver
    end
    
    def parse()
      expr = parse_expr()
      raise "invalid xpath [#{@scanner.rest}]" unless @scanner.eos?
      expr
    end
    
    def parse_expr()
      parse_or_expr()
    end
    
    def parse_or_expr()
      expr = parse_and_expr()
      if @scanner.check( /or/u ) then
        tmp = expr
        expr = OrExpr.new()
        expr << tmp
        while @scanner.scan( /or/u ) do
          expr << parse_and_expr()
        end
      end
      expr
    end
    
    def parse_and_expr()
      expr = parse_equality_expr()
      if token = @scanner.check( /and/u ) then
        tmp = expr
        expr = AndExpr.new()
        expr << tmp
        while @scanner.scan( /and/u ) do
          expr << parse_equality_expr()
        end
      end
      expr
    end
    
    def parse_equality_expr()
      expr = VCDOM::XPath::Internal::EqualityExpr.new()
      parse_relational_expr( expr )
      while token = @scanner.scan( /=|\!=/u ) do
        parse_relational_expr( expr )
        expr << VCDOM::XPath::Internal.get_operation_command( token.intern )
      end
      expr
    end
    
    def parse_relational_expr( expr )
      parse_additive_expr( expr )
      while token = @scanner.scan( /\<=?|\>=?/u ) do
        parse_additive_expr( expr )
        expr << VCDOM::XPath::Internal.get_operation_command( token.intern )
      end
    end
    
    def parse_additive_expr( expr )
      parse_multiplicative_expr( expr )
      while token = @scanner.scan( /\+|\-/u ) do
        parse_multiplicative_expr( expr )
        expr << VCDOM::XPath::Internal.get_operation_command( token.intern )
      end
    end
    
    def parse_multiplicative_expr( expr )
      parse_unary_expr( expr )
      while token = @scanner.scan( /\*|div|mod/u ) do
        parse_unary_expr( expr )
        expr << VCDOM::XPath::Internal.get_operation_command( token.intern )
      end
    end
    
    def parse_unary_expr( expr )
      num = 0
      while @scanner.scan( /\-/u ) do
        num += 1
      end
      parse_union_expr( expr )
      num.times do
        expr << VCDOM::XPath::Internal.get_operation_command( :"-@" )
      end
    end
    
    def parse_union_expr( expr )
      parse_path_expr( expr )
      while @scanner.scan( /\|/u ) do
        parse_path_expr( expr )
        expr << VCDOM::XPath::Internal.get_operation_command( :"|" )
      end
    end
    
    XPATH_PATH_EXPR_STARTER_REGEXP = /#{xpath_number}|#{xpath_literal}|#{xpath_anyname}|\/\/?|\.\.?|@|\(/u
    XPATH_VARIABLE_REFERENCE_REGEXP = /\$#{xml_q_name}/u
    XPATH_NUMBER_REGEXP  = /#{xpath_number}/u
    XPATH_LITERAL_REGEXP = /#{xpath_literal}/u
    XPATH_NAME_TEST = /(?:#{xml_nc_name}:)?\*|#{xml_q_name}/u
    XPATH_STEP_STARTER_REGEXP = /\*|\.\.?|@|#{xml_q_name}/u
    # VariableReference
    # '(' Expr ')'
    # Literal
    # Number
    # FunctionCall
    def parse_path_expr( expr )
      is_path = false
      if token = @scanner.scan( XPATH_NUMBER_REGEXP ) then
        # Number の場合
        expr << VCDOM::XPath::Internal::NumberValue.new( token.to_f() )
      elsif token = @scanner.scan( XPATH_LITERAL_REGEXP) then
        # Literal の場合
        token[0,1]  = ""
        token[-1,1] = ""
        expr << VCDOM::XPath::Internal::StringValue.new( token )
      elsif token = @scanner.scan( XPATH_VARIABLE_REFERENCE_REGEXP ) then
        # VariableReference の場合
        raise "VariableReference is not supported"
      elsif @scanner.scan( /\(/u ) then
        # "(" Expr ")" の場合
        expr << VCDOM::XPath::Internal::ExprEvalCommand.new( parse_expr() )
        raise "invalid xpath expression" unless @scanner.scan( /\)/u )
      else
        # Path or FunctionCall
        pos = @scanner.pos
        is_path = true
        if token = @scanner.scan( XML_Q_NAME ) then
          # FunctionName or AxisName or NameTest or NodeType
          if @scanner.scan( /\(/u ) then
            # FunctionName or NodeType
            case token
            when "comment", "text", "processing-instruction", "node"
              # do nothing
            else
              # FunctionName
              is_path = false
            end
          end
        end
        if is_path then
          # Path
          @scanner.pos = pos
          if token = @scanner.scan( /\/\/?/u ) then
            # "/" or "//"
            expr << VCDOM::XPath::Internal::RootNodeCommand.get_instance()
            if token == "/" then
              # 続く要素がなければここで終了
              return unless @scanner.check( XPATH_STEP_STARTER_REGEXP )
            else # "//"
              expr << VCDOM::XPath::Internal::NodeSelectionCommand.new( :"descendant-or-self", :node, nil, nil, nil )
            end
          else
            expr << VCDOM::XPath::Internal::ContextNodeCommand.get_instance()
          end
          expr << parse_step()
        else
          # FunctionCall
          function_name = token.intern
          arg_exprs = @scanner.check( /\)/u ) ? nil : parse_expr_list()
          raise "invalid xpath [#{@scanner.rest}]" unless @scanner.scan( /\)/u )
          expr << FunctionCallCommand.new( function_name, arg_exprs )
        end
      end
      if not is_path then
        if @scanner.check( /\[/u ) then
          pred_exprs = parse_predicates()
          expr << PredsEvalCommand.new( pred_exprs )
        end
      end
      while token = @scanner.scan( /\/\/?/ ) do
        if token == "//" then
          expr << VCDOM::XPath::Internal::NodeSelectionCommand.new( :"descendant-or-self", :node, nil, nil, nil )
        end
        expr << parse_step()
      end
    end
    
    AXIS_NAME_LIST = [ :'ancestor', :'ancestor-or-self', :'attribute', :'child', :'descendant', :'descendant-or-self', 
          :'following', :'following-sibling', :'namespace', :'parent', :'preceding', :'preceding-sibling', :'self' ]
    NODE_TYPE_LIST = [ :'comment', :'text', :'processing-instruction', :'node' ]
    def parse_step()
      # "." or ".."
      if @scanner.scan( /\.\./u ) then
        return VCDOM::XPath::Internal::NodeSelectionCommand.new( :parent, :node, nil, nil, nil )
      elsif token = @scanner.scan( /\./u ) then
        return VCDOM::XPath::Internal::NodeSelectionCommand.new( :self, :node, nil, nil, nil )
      end
      # AxisName
      pos = @scanner.pos
      if @scanner.scan( /@/u ) then
        axis_name = :attribute
      elsif token = @scanner.scan( XML_Q_NAME ) then
        if @scanner.scan( /::/u ) then
          axis_name = token.intern
          raise "invalid AxisName [#{axis_name}]" unless AXIS_NAME_LIST.include? axis_name
        else
          axis_name = :child
          @scanner.pos = pos
        end
      else
        axis_name = :child
      end
      # NameTest or NodeType
      if token = @scanner.scan( XPATH_NAME_TEST ) then
        if @scanner.scan( /\(/u ) then
          # NodeType
          node_type = token.intern
          raise "invalid NodeType [#{node_type}]" unless NODE_TYPE_LIST.include? node_type
          node_name = ( node_type == :"processing-instruction" and token = @scanner.scan( XPATH_LITERAL ) ) ? token.intern : nil
          node_ns_uri = nil
          raise "invalid xpath expression" unless @scanner.scan( /\)/u )
        else
          # NameTest
          node_type = :named_node
          name_pair = token.split( /:/u )
          if name_pair.length == 2 then
            node_name = ( name_pair[1] == "*" ) ? nil : name_pair[1].intern
            node_ns_uri = @ns_resolver.lookup_namespace_uri( name_pair[0] )
            node_ns_uri.nil? or node_ns_uri = node_ns_uri.intern
          else
            # length == 1
            node_name = ( name_pair[0] == "*" ) ? nil : name_pair[0].intern
            node_ns_uri = nil
          end
        end
      else
        raise "invalid xpath expression [#{@scanner.rest}]"
      end
      # Predicate
      pred_exprs = @scanner.check( /\[/u ) ? parse_predicates() : nil
      VCDOM::XPath::Internal::NodeSelectionCommand.new( axis_name, node_type, node_ns_uri, node_name, pred_exprs )
    end
    
    def parse_expr_list()
      exprs = Array.new()
      exprs << parse_expr()
      while @scanner.scan( /,/u ) do
        exprs << parse_expr()
      end
      exprs
    end
    
    def parse_predicates()
      exprs = Array.new()
      while @scanner.scan( /\[/u ) do
        exprs << parse_expr()
        raise "invalid xpath expression" unless @scanner.scan( /\]/u )
      end
      exprs
    end
    
  end
end
