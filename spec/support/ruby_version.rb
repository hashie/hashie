def mri22?
  ruby_version.start_with?('ruby_2.2')
end

def ruby_version
  interpreter = Object.const_defined?(:RUBY_ENGINE) && RUBY_ENGINE
  version = Object.const_defined?(:RUBY_VERSION) && RUBY_VERSION

  "#{interpreter}_#{version}"
end
