# -*- encoding: utf-8 -*-

require 'bundler'

Gem::Specification.new do |s|
  s.name = %q{hashie}
  s.version = File.read("VERSION")

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Bleigh"]
  s.date = %q{2010-03-05}
  s.description = %q{Hashie is a small collection of tools that make hashes more powerful. Currently includes Mash (Mocking Hash) and Dash (Discrete Hash).}
  s.email = %q{michael@intridea.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = Dir["**/*"]
  s.add_bundler_dependencies
  s.homepage = %q{http://github.com/intridea/hashie}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Your friendly neighborhood hash toolkit.}
  s.test_files = [
    "spec/hashie/clash_spec.rb",
     "spec/hashie/dash_spec.rb",
     "spec/hashie/hash_spec.rb",
     "spec/hashie/mash_spec.rb",
     "spec/spec_helper.rb"
  ]
end

