# coding : utf-8

# @private
module VCDOM::XPath::Internal # :nodoc:
  
  # @private
  class AbstractValue # :nodoc:
    
    def is_value?;   true  end
    def is_expr?;    false end
    def is_command?; false end
    
    def to_s()
      "XPathValue(#{value})"
    end
    
    def -@(); - self.to_number_value end
    def +( val ); self.to_number_value + val end
    def -( val ); self.to_number_value - val end
    def *( val ); self.to_number_value * val end
    def /( val ); self.to_number_value / val end
    def %( val ); self.to_number_value % val end
    
    def |( val )
      raise "User Error : xpath operator \"|\" must operate NodeSet"
    end
    
    def ==( val )
      types = [ self.value_type, val.value_type ]
      if types.include? :boolean then
        return val.to_boolean_value.value == self.to_boolean_value.value ? BooleanValue.true : BooleanValue.false
      elsif types.include? :node_set then
        # TODO : node-set が含まれている場合
        val == self
      elsif types.include? :number
        return val.to_number_value.value == self.to_number_value.value ? BooleanValue.true : BooleanValue.false
      else
        return val.to_string_value.value == self.to_string_value.value ? BooleanValue.true : BooleanValue.false
      end
    end
    
    def neq?( val )
      if val.value_type == :node_set then
        return val.neq? self
      else
        return ( self == val ? BooleanValue.false : BooleanValue.true )
      end
    end
    
    def <=>( val )
      if val.value_type == :node_set then
        return ( val <=> self ) * -1
      else
        return self.to_number_value.value <=> val.to_number_value.value
      end
    end
    def <( val )
      ( self <=> val ) < 0 ? BooleanValue.true : BooleanValue.false
    end
    def <=( val )
      ( self <=> val ) <= 0 ? BooleanValue.true : BooleanValue.false
    end
    def >( val )
      ( self <=> val ) > 0 ? BooleanValue.true : BooleanValue.false
    end
    def >=( val )
      ( self <=> val ) >= 0 ? BooleanValue.true : BooleanValue.false
    end
    
  end
  
  # @private
  class NumberValue < AbstractValue # :nodoc:
    
    def initialize( val )
      @value = val.to_f
    end
    ##
    # NaN -> "NaN"
    # 正ゼロ, 負ゼロ -> "0"
    # 正の無限大 -> "Infinity"
    # 負の無限大 -> "-Infinity"
    # 数値が整数である場合, 数値は 10 進形式で, 小数点がなく先頭のゼロもない [0-9]+ として表現され,
    # 数値が負である場合には負号 (-) が前につく
    # それ以外 -> 数値は 10 進形式で [0-9]+ "." [0-9]+ として表現され, 数値が負である場合には負号 (-) が前につく
    # 小数点の直前にある必須の数字 1 個を別として, 小数点の前に先頭のゼロがあってはならない. 
    # 小数点の後の必須の数字1個を越えてそれ以上の数字は, その数値をその他すべての IEEE 754 数値から一意的に区別するのに
    # 必要な数字がなければならないが, 必要なだけしかあってはならない
    def to_string_value()
      if @value.nan? then
        str = StringValue.new("NaN")
      elsif @value.infinite? == 1 then
        str = StringValue.new("Infinity")
      elsif @value.infinite? == -1 then
        str = StringValue.new("-Infinity")
      elsif @value.zero? then
        str = StringValue.new("0")
      elsif @value.truncate == @value then
        str = StringValue.new(@value.to_i.to_s)
      else
        str = StringValue.new(@value.to_s)
      end
      str
    end
    
    def to_number_value()
      self
    end
    
    # 数値は、正または負のゼロでなくNaNでもない場合に、かつない場合にのみ、真である。
    def to_boolean_value()
      ( @value.zero? || @value.nan? ) ? BooleanValue.false : BooleanValue.true
    end
    
    attr_reader :value
    def value_type; :number end
    
    # define operations
    
    def -@(); @value = - @value; self end
    def +( val ); NumberValue.new( @value + val.to_number_value.value ) end
    def -( val ); NumberValue.new( @value - val.to_number_value.value ) end
    def *( val ); NumberValue.new( @value * val.to_number_value.value ) end
    def /( val ); NumberValue.new( @value / val.to_number_value.value ) end
    def %( val )
      value1 = val.to_number_value.value
      value1 < 0 && value1 = -value1
      value2 = @value
      if value2 < 0 then
        value2 = - value2
        value2 %=  value1
        value2 = - value2
      else
        value2 %=  value1
      end
      NumberValue.new( value2 )
    end
    
  end
  
  # @private
  class StringValue < AbstractValue # :nodoc:
    
    def initialize( val )
      @value = val.to_s
    end
    def to_string_value()
      self
    end
    
    # StringValue を NumberValue に変換する
    # オプションの空白にオプションの負号 1 個が続き, [0-9]("." [0-9]*)? | "." [0-9]+ が続いて空白が続いたものからなる文字列は, 
    # その文字列が表す数学的値に (IEEE 754 最近接値丸めルールに従い) 最も近い IEEE 754 数値に変換される.
    # その他の文字列はどれも NaN に変換される.
    def to_number_value()
      str = @value.gsub( /[\x20\x09\x0A\x0D]/u, "" )
      if str =~ /\A\-?(?:\d+(?:\.\d*)?|\.\d+)\Z/ then
        # NaN
        return NumberValue.new( str.to_f )
      else
        # NaN
        return NumberValue.new( 0.0 / 0.0 )
      end
    end
    
    # 文字列は、その長さが非ゼロである場合に、かつ非ゼロである場合にのみ、真である。 
    def to_boolean_value()
      @value.length != 0 ? BooleanValue.true : BooleanValue.false
    end
    
    attr_reader :value
    def value_type; :string end
    
  end
  
  # @private
  class BooleanValue < AbstractValue # :nodoc:
    
    def initialize( val )
      @value = !! val
    end
    def to_string_value()
      @value ? StringValue.new("true") : StringValue.new("false")
    end
    
    # convert a BooleanValue object to a NumberValue object.
    # オプションの空白にオプションの負号 1 個が続き, [0-9]("." [0-9]*)? | "." [0-9]+ が続いて空白が続いたものからなる文字列は, 
    # その文字列が表す数学的値に (IEEE 754 最近接値丸めルールに従い) 最も近い IEEE 754 数値に変換される.
    # その他の文字列はどれも NaN に変換される.
    def to_number_value()
      @value ? NumberValue.new( 1.0 ) : NumberValue.new( 0.0 )
    end
    
    def to_boolean_value()
      self
    end
    
    attr_reader :value
    def value_type; :boolean end
    
    TRUE  = self.new( true )
    FALSE = self.new( false )
    def self.true;  TRUE  end
    def self.false; FALSE end
    
  end
  
  # @private
  class NodeSetValue < AbstractValue # :nodoc:
    
    def initialize( *nodes )
      @value = nodes
    end
    
    def to_string_value()
      self.sort()
      @value.empty? ? StringValue.new("") : StringValue.new( @value[0].text_content )
    end
    
    def to_number_value()
      self.to_string_value().to_number_value()
    end
    
    def to_boolean_value()
      @value.empty? ? BooleanValue.false : BooleanValue.true
    end
    
    def []( *args )
      @value.[]( *args )
    end
    def <<( node )
      @value << node
    end
    
    def sort( document_order = true )
      # TODO
      return
      @value.sort! do |a,b|
        case a.compare_document_position(b)
        when :document_position_preceding, :document_position_contains then # a が b よりも前
        when :document_position_following, :document_position_contained_by then # a が b より後ろ
        else
          raise "node-set contains nodes which contained by each other trees"
        end
      end
    end
    
    def each
      # TODO : ブロックが与えられなかった場合の処理
      @value.each do |v|
        yield v
      end
    end
    def each_with_index
      # TODO : ブロックが与えられなかった場合の処理
      @value.each_with_index do |v,i|
        yield v,i
      end
    end
    
    def length
      @value.length
    end
    
    attr_reader :value
    def value_type; :node_set end
    
    def |( val )
      val.|(self) if val.value_type != :node_set
      @value = @value + val.value
      @value.uniq!
      self
    end
    
    # 比較されるべきオブジェクトの双方がノードセットである場合、比較は、2つのノードの文字列値について
    # 比較を実行した結果が真であるようなノードが、1つ目のノードセットと2つ目のノードセットとにある場合に、
    # かつある場合にのみ、真ということになる。比較されるべきオブジェクトの一方がノードセットであり、
    # 他方が数値である場合、比較は、比較されるべき数値と、number 関数を用いてノードの文字列値を数値に変換
    # した結果とについて比較を実行した結果が真であるようなノードが、ノードセットの中にある場合に、かつある
    # 場合にのみ、真ということになる。比較されるべきオブジェクトの一方がノードセットであり、他方が文字列で
    # ある場合、比較は、ノードの文字列値と他方の文字列とについて比較を実行した結果が真であるようなノードが、
    # ノードセットの中にある場合に、かつある場合にのみ、真ということになる。比較されるべきオブジェクトの一方が
    # ノードセットであり、他方がブール値である場合、比較は、ブール値と、boolean 関数を用いてノードセット
    # をブール値に変換した結果とについて比較を実行した結果が真である場合に、かつ真である場合にのみ、真ということになる。 
    def ==( val )
      case val.value_type
      when :node_set
        @value.each do |node1|
          str1 = StringValue.new( node1.text_content )
          val.each do |node2|
            return BooleanValue.true if ( str1 == StringValue.new( node2.text_content ) ) == BooleanValue.true
          end
        end
        return BooleanValue.false
      when :number
        # TODO
        raise "NOT SUPPORT"
      when :string
        # TODO
        raise "NOT SUPPORT"
      when :boolean
        return val == self
      end
    end
    
    def neq?( val )
      case val.value_type
      when :node_set
        @value.each do |node1|
          str1 = StringValue.new( node1.text_content )
          val.each do |node2|
            return BooleanValue.true if ( str1.neq? StringValue.new( node2.text_content ) ) == BooleanValue.true
          end
        end
        return BooleanValue.false
      when :number
        # TODO
        raise "NOT SUPPORT"
      when :string
        # TODO
        raise "NOT SUPPORT"
      when :boolean
        return val.neq? self
      end
    end
    
    def <=>( val )
      # TODO
      case val.value_type
      when :node_set
        @value.each do |node1|
          str1 = StringValue.new( node1.text_content )
          val.each do |node2|
            return BooleanValue.true if ( str1 <=> StringValue.new( node2.text_content ) ) == BooleanValue.true
          end
        end
        return BooleanValue.false
      when :number
        # TODO
        raise "NOT SUPPORT"
      when :string
        # TODO
        raise "NOT SUPPORT"
      when :boolean
        return self.to_boolean_value <=> val
      end
    end
    
  end
  
end
