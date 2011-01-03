# coding : utf-8

module VCDOM::XPath::Internal # :nodoc:
  
  class AbstractExpr < Array # :nodoc:
    def initialize( *expr_elems )
      expr_elems.each do |e|
        self << e
      end
    end
    
    def is_value?;   false end
    def is_expr?;    true  end
    def is_command?; false end
  end
  
  class OrExpr < AbstractExpr # :nodoc:
    def expr_type
      :or_expr
    end
  end
  
  class AndExpr < AbstractExpr # :nodoc:
    def expr_type
      :and_expr
    end
  end
  
  class EqualityExpr < AbstractExpr # :nodoc:
    def expr_type
      :equality_expr
    end
  end
  
end
