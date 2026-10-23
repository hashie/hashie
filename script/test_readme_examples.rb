# frozen_string_literal: true

require 'hashie'
require 'kramdown'
require 'kramdown-parser-gfm'
require 'tmpdir'

module ReadmeExamples
end

examples = Hash.new { |hash, key| hash[key] = +'' }
group = nil
document = Kramdown::Document.new(File.read('README.md'), input: 'GFM')
visit = lambda do |node|
  if node.type == :xml_comment && node.value =~ /hashie:example ([\w-]+)/
    group = Regexp.last_match(1)
  elsif node.type == :codeblock && node.options[:lang] == 'ruby'
    examples[group || node.options[:location]] << node.value << "\n"
    group = nil
  end
  node.children.each(&visit)
end
visit.call(document.root)
abort 'no README Ruby examples found' if examples.empty?

examples.each do |name, code|
  logger = Hashie.logger
  begin
    Hashie::Mash.instance_variable_set(:@_mashes, nil)
    Dir.mktmpdir('hashie-readme-') do |directory|
      Dir.chdir(directory) do
        namespace = ReadmeExamples.const_set(:Context, Module.new)
        namespace.extend(namespace)
        namespace.module_eval(code, "README.md (#{name})", 1)
      end
    end
  ensure
    Hashie.logger = logger
    ReadmeExamples.send(:remove_const, :Context) if ReadmeExamples.const_defined?(:Context, false)
  end
end
puts "#{examples.size} README examples ran successfully"
