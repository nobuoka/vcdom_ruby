# coding : utf-8

require "vcdom/character_data"
require "vcdom/child"

module VCDOM
  
  class Text < CharacterData
    
    include Child
    
    def initialize( doc, data )
      super( doc, data )
    end
    
    def node_type
      TEXT_NODE
    end
    def node_name
      "#text"
    end
    
  end
  
end
