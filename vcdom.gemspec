# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  
  s.name    = "vcdom"
  s.version = "0.3.0"
  
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["nobuoka"]
  s.date = "2010-12-04"
  s.description = "This gem is a one of implementations of W3C DOM...."
  s.email = %q{nobuoka@r-definition.com}
  s.extra_rdoc_files = [
    #"LICENSE",
    #"README.rdoc"
  ]
  s.files = [
    #".document",
    #".gitignore",
    #"LICENSE",
    #"README.rdoc",
    #"Rakefile",
    #"VERSION",
    "lib/vcdom/attr.rb",
    "lib/vcdom/attr_ns.rb",
    "lib/vcdom/attr_node_map.rb",
    "lib/vcdom/character_data.rb",
    "lib/vcdom/child.rb",
    "lib/vcdom/document.rb",
    "lib/vcdom/element.rb",
    "lib/vcdom/element_ns.rb",
    "lib/vcdom/node.rb",
    "lib/vcdom/node_list.rb",
    "lib/vcdom/parent.rb",
    "lib/vcdom/text.rb",
    "lib/vcdom/xml_parser.rb",
    "lib/vcdom/xml_serializer.rb",
    #"test/main_test.rb",
    #"test/main_test_1.8.rb",
    #"test/main_test_1.9.rb",
    #"test/test_test.rb"
  ]
  #s.homepage = %q{http://github.com/nobuoka/test}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = "This gem is a one of implementations of W3C DOM."
  s.test_files = [
    #"test/main_test.rb",
    #"test/main_test_1.8.rb",
    #"test/main_test_1.9.rb",
    #"test/test_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    else
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
  end
end
