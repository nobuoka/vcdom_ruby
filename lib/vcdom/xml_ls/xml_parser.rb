# coding : utf-8

require "vcdom/document"

module VCDOM::XMLLS
  
  class XMLInput
    def string_data
      @string_data
    end
    def string_data=( str_data )
      @string_data = str_data
    end
  end
  
  class XMLContentHandler # :nodoc:
    def initialize( document_class )
      @document_class = document_class
      @ns_stack = Array.new()
    end
    def ns_stack
      @ns_stack
    end
    def start_document
      @doc = @document_class._new()
      @cur = @doc
    end
    def end_document
      return @doc
    end
    def on_stag( name, ns_uri )
      @cur = @cur.append_child( @doc.create_element_ns( ns_uri, name ) )
    end
    def on_etag( name )
      if @cur.node_name != name then
        raise "[ERROR] @cur.node_name : #{@cur.node_name}, name : #{name}"
      end
      @cur = @cur.parent_node
    end
    def on_eetag( name, ns_uri )
      @cur = @cur.append_child( @doc.create_element_ns( ns_uri, name ) )
    end
    def on_end_eetag()
      @cur = @cur.parent_node
    end
    def on_begin_attr( name, ns_uri )
      attr = @doc.create_attribute_ns( ns_uri, name )
      @cur.set_attribute_node_ns( attr )
      @cur = attr
    end
    def on_end_attr()
      @cur = @cur.owner_element
    end
    def on_chardata( char_data )
      if @cur.node_type == VCDOM::Node::DOCUMENT_NODE then
        if char_data !~ /\A[\x20\x09\x0D\x0A]*\Z/ then
          raise "ERROR : " + char_data.inspect
        end
      else
        @cur.append_child( @doc.create_text_node( char_data ) )
      end
    end
  end
  
  class XMLParser
    
    def parse( input )
      source = input.string_data
      if source.class == String then
        # Ruby 1.8 の場合, String を 1 文字ずつに分ける
        if RUBY_VERSION < "1.9"
          source = source.split //u
          class << source
            def []( *args )
              res = super( *args )
              args.length == 2 ? res.join : res
            end
          end
        end
        _parse_xml_str( source, XMLContentHandler.new( VCDOM::Document ) )
      else
        raise ArgumentTypeError.new()
      end
    end
    
    def _parse_xml_str( xml_str, content_handler )
      content_handler.start_document()
      i = 0
      loop do
        if xml_str[i].nil? then
          break
        elsif xml_str[i] == "<" then
          i += 1
          if xml_str[i] == "/" then
            # ETag ::= '</' Name S? '>'
            i = _parse_end_tag( xml_str, i+1, content_handler )
          elsif xml_str[i] == "?" then
            # PI
          elsif xml_str[i] == "!" then
            i += 1
            if xml_str[i,2] == "--" then
              # Comment ::= '<!--' ((Char - '-') | ('-' (Char - '-')))* '-->'
              i = _parse_comment( xml_str, i+2, content_handler )
            elsif xml_str[i,7] == "[CDATA[" then
              # CDATA
              i = _parse_cdata( xml_str, i+7, content_handler )
            else
              $stdout << "ERROR" << "\n"
            end
          else
            i = _parse_stag_or_eetag( xml_str, i, content_handler )
          end
        elsif xml_str[i] == "&" and not _is_char_ref_or_predef_entity_ref?( xml_str, i ) then
          raise "NOT SUPPORT"
          # Reference ::= EntityRef | CharRef
          #   EntityRef ::= '&' Name ';'
          #   CharRef   ::= '&#' [0-9]+ ';' | '&#x' [0-9a-fA-F]+ ';'
        else
          # CharData ::= [^<&]* - ([^<&]* ']]>' [^<&]*)
          i = _parse_chardata_or_entity_reference( xml_str, i, content_handler )
        end
      end
      return content_handler.end_document()
    end
    private :_parse_xml_str
    
    def _parse_stag_or_eetag( str, i, content_handler )
        #@listener.on_begin_stag_or_eetag()
        # 要素名の取得
        elem_name = String.new()
        loop do
          if str[i] != ">" and str[i] != "/" and str[i] != " " then
            elem_name << str[i]
            i += 1
          else
            break
          end
        end
        if elem_name.length != 0 then
          #@listener.on_tag_name( elem_name )
        else
          $stdout << "ERROR" << "\n"
        end
        # 属性の取得
        attrs = Array.new()
        ns_attrs = Array.new()
        loop do
          # 空白の除去
          i = _skip_white_spaces( str, i )
          # 属性リストの終了を確認
          if str[i] == "/" or str[i] == ">" then
            break
          end
          # 属性名の取得
          attr_name = String.new()
          loop do
            if str[i] and str[i] != "=" and str[i] != " " then
              attr_name << str[i]
              i += 1
            else
              break
            end
          end
          # 空白の除去
          i = _skip_white_spaces( str, i )
          # 等値記号の確認
          if str[i] == "=" then
            i += 1
          else
            raise "[ERROR] str[i] : #{str[i]}"
          end
          # 空白の除去
          i = _skip_white_spaces( str, i )
          # 属性値の取得
          if str[i] == "\"" or str[i] == "'" then
            quot = str[i]
            i += 1
          else
            raise "[ERROR] str[i] : #{str[i]}"
          end
          attr_val = String.new
          loop do
            if str[i] and str[i] != quot then
              attr_val << str[i]
              i += 1
            else
              break
            end
          end
          if str[i] == quot then
            i += 1
          else
            raise "ERROR"
          end
          if attr_name == "xmlns" or attr_name[0,6] == "xmlns:" then
            ns_attrs << [ attr_name, attr_val ]
          else
            attrs << [ attr_name, attr_val ]
          end
        end
        # 空白の除去
        i = _skip_white_spaces( str, i )
        # この要素で使える名前空間 prefix を調整
        if content_handler.ns_stack[-1] then
          ns_map = content_handler.ns_stack[-1]
        else
          ns_map = { nil => nil }
        end
        if ns_attrs.length != 0 then
          ns_map = ns_map.clone
          ns_attrs.each do |ns_pair|
            # ns_pair[0] : attr_name, ns_pair[1] : attr_value
            if ns_pair[0] == "xmlns" then
              ns_map[nil] = ns_pair[1]
            else
              ns_map[ ns_pair[0][6..-1].intern ] = ns_pair[1]
            end
          end
        end
        # 最後の ">" または "/>" の確認
        is_eetag = false
        if str[i] == ">" then
          # 名前空間スタックに積む
          content_handler.ns_stack.push( ns_map )
          i += 1
        elsif str[i] == "/" and str[i+1] == ">" then
          is_eetag = true
          i += 2
        else
          $stdout << "ERROR" << "\n"
        end
        # 要素の処理
        name_pair = elem_name.split /:/
        if name_pair.length == 1 then
          ns_uri = ns_map[nil]
        elsif name_pair.length == 2 then
          if name_pair[0] != "xml" then
            ns_uri = ns_map[ name_pair[0].intern ]
          else
            ns_uri = "http://www.w3.org/XML/1998/namespace"
          end
        else
          raise "ERROR"
        end
        if is_eetag then
          content_handler.on_eetag( elem_name, ns_uri )
        else
          content_handler.on_stag( elem_name, ns_uri )
        end
        # 属性の処理
        ns_attrs.each do |attr|
          content_handler.on_begin_attr( attr[0], "http://www.w3.org/2000/xmlns/" )
          content_handler.on_chardata( attr[1] ) if attr[1]
          content_handler.on_end_attr()
        end
        attrs.each do |attr|
          if attr[0][0,4] == "xml:" then
            content_handler.on_begin_attr( attr[0], "http://www.w3.org/XML/1998/namespace" )
          else
            name_pair = attr[0].split /:/
            if name_pair.length == 1 then
              content_handler.on_begin_attr( attr[0], nil )
            elsif name_pair.length == 2 then
              content_handler.on_begin_attr( attr[0], ns_map[ name_pair[0].intern ] )
            end
          end
          content_handler.on_chardata( attr[1] ) if attr[1]
          content_handler.on_end_attr()
        end
        if is_eetag then
          content_handler.on_end_eetag()
        end
        return i
      end
      private :_parse_stag_or_eetag
      
      def _parse_end_tag( str, i, content_handler )
        # 要素名の取得
        elem_name = String.new
        loop do
          if str[i] != ">" && str != " " then
            elem_name << str[i]
            i += 1
          else
            break
          end
        end
        if elem_name.length == 0 then
          $stdout << "ERROR" << "\n"
        end
        # 空白の除去
        i = _skip_white_spaces( str, i )
        if str[i] == ">" then
          i += 1
        else
          $stdout << "ERROR" << "\n"
        end
        content_handler.on_etag( elem_name )
        # 名前空間スタックにから取り出す
        content_handler.ns_stack.pop()
        return i
      end
      private :_parse_end_tag
      
      def _is_char_ref_or_predef_entity_ref?( str, i )
        if str[i] == "&" then
          if str[i+1] == "#" then
            return true
          elsif str[i+2,3] == "lt;" or str[i+2,3] == "gt;" or str[i+2,5] == "quot;" or
                  str[i+2,5] == "apos;" or str[i+2,4] == "amp;" then
            return true
          else
            return false
          end
        end
      end
      private :_is_char_ref_or_predef_entity_ref?
      
      def _parse_chardata_or_entity_reference( str, i, content_handler )
        # CharData ::= [^<&]* - ([^<&]* ']]>' [^<&]*)
        chardata = String.new()
        loop do
          if str[i].nil? or str[i] == "<" then
            break
          #elsif str[i] == "]" and str[i+1] == "]" and str[i+2] == ">" then
          #  break
          elsif str[i] == "&" then
            if str[i+1] != "#" then
              if str[i+1,3] == "lt;" then
                chardata << "<"
                i += 4
              elsif str[i+1,3] == "gt;" then
                chardata << ">"
                i += 4
              elsif str[i+1,5] == "quot;" then
                chardata << "\""
                i += 6
              elsif str[i+1,5] == "apos;" then
                chardata << "'"
                i += 6
              elsif str[i+1,4] == "amp;" then
                chardata << "&"
                i += 5
              else
                # entity reference
                break
              end
            else
              # when character reference
              i += 2
              num = String.new()
              loop do
                if str[i].nil? then
                  raise "ERROR"
                elsif str[i] != ";" then
                  num << str[i]
                  i += 1
                else
                  break
                end
              end
              if num[0] == "x" then
                num = num[1..-1].to_i(16)
              else
                num = num.to_i
              end
              chardata << [num].pack("U")
              if str[i] == ";" then
                i += 1
              else
                raise "ERROR"
              end
            end
          else
            chardata << str[i]
            i += 1
          end
        end
        content_handler.on_chardata( chardata )
        return i
      end
      private :_parse_chardata_or_entity_reference
      
      def _skip_white_spaces( str, i )
        loop do
          if str[i] == " " then
            i += 1
          else
            break
          end
        end
        return i
      end
      private :_skip_white_spaces
      
    end
end
