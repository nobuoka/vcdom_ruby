# coding : utf-8

require "vcdom/node"
require "vcdom/attr"

module VCDOM
    class AttrNS < Attr
      
      def initialize( doc, namespace_uri, prefix, local_name )
        super( doc, local_name )
        @namespace_uri = namespace_uri
        @prefix = prefix
      end
      
      def name
        if @prefix then
          "#{@prefix.to_s}:#{@local_name.to_s}"
        else
          @local_name.to_s()
        end
      end
      alias :node_name :name
      
      def prefix
        @prefix.nil? ? nil : @prefix.to_s()
      end
      def prefix=(val)
        @prefix = val.nil? ? nil : val.intern
      end
      def local_name
        @local_name.to_s()
      end
      def namespace_uri
        @namespace_uri.nil? ? nil : @namespace_uri.to_s()
      end
      
    end
end
