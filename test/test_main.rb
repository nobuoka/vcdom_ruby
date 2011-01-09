#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift File.dirname(__FILE__)
$LOAD_PATH.unshift File.join( File.dirname(__FILE__), "..", "lib" )

require "core/test_element"
require "core/test_attr"
require "core/test_text"
require "test_parsing"
require "test_xpath"
