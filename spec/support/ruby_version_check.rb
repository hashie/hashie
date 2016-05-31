module RubyVersionCheck
  def with_minimum_ruby(version)
    yield if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new(version)
  end
end
