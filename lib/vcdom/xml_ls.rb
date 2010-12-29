# coding : utf-8

require "vcdom/xml_ls/xml_parser"
require "vcdom/xml_ls/xml_serializer"

module VCDOM
  module XMLLS
    
    extend self
    
    MODE_SYNCHRONOUS  = :mode_synchronous
    MODE_ASYNCHRONOUS = :mode_asynchronous
    
    def create_ls_parser( mode, schema_type )
      case mode
      when MODE_ASYNCHRONOUS
        # OK : do nothing
      when MODE_SYNCHRONOUS
        raise "SORRY... arg +mode+ is not supported. must be +MODE_ASYNCHRONOUS+"
      else
        raise ArgumentError.new( "invalid mode [" + mode.inspect + "]" )
      end
      if not schema_type.nil? then
        raise "SORRY... arg +schema_type+ is not still supported. must be +nil+"
      end
      XMLParser.new()
    end
    
    def create_ls_serializer()
      XMLSerializer.new()
    end
    
    def create_ls_input()
      XMLInput.new()
    end
    
    def create_ls_output()
      XMLOutput.new()
    end
    
  end
end
