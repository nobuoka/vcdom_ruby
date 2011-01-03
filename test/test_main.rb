#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift File.dirname(__FILE__)
$LOAD_PATH.unshift File.join( File.dirname(__FILE__), "..", "lib" )

require "test_parsing"
require "test_xpath"
