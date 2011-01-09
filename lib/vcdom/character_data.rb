# coding : utf-8

require "vcdom/node"

module VCDOM
  
  class CharacterData < Node
    
    # @private
    def initialize( doc, data ) # :nodoc:
      super( doc )
      @data = data
    end
    
    def data
      @data.to_s
    end
    def data=( val )
      @data = val.intern
    end
    alias :node_value    :data
    alias :node_value=   :data=
    alias :text_content  :data
    alias :text_content= :data=
    
    def length
      @data.to_s.length
    end
    
  end
  
end
