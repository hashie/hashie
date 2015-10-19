# How to pend specs that break due to bugs in Ruby interpreters or versions
#
#   it("blah is blah") do
#     pending_for(engine: 'jruby', version: '2.2.2')
#     expect('blah').to eq 'blah'
#   end
#
def pending_for(options = {}) # Not using named parameters because still supporting Ruby 1.9
  fail ArgumentError, 'pending_for requires at least an engine or versions to be specified' unless
      options[:engine] || options[:versions]
  current_engine, current_version = ruby_engine_and_version
  versions_to_pend = Array(options[:versions]) # cast to array
  engine_to_pend = options[:engine]
  broken = 'This behavior is broken'
  bug = 'due to a bug in the Ruby engine'
  # If engine is nil, then any matching versions should be pended
  if engine_to_pend.nil?
    pending "#{broken} in Ruby versions #{versions_to_pend} #{bug}" if
        versions_to_pend.include?(current_version)
  elsif engine_to_pend == current_engine
    if versions_to_pend.empty?
      pending "#{broken} #{bug} #{INTERPRETER_MATRIX[engine_to_pend]}"
    else
      pending %[#{broken} in Ruby versions #{versions_to_pend} #{bug} (#{INTERPRETER_MATRIX[engine_to_pend]})] if
          versions_to_pend.include?(current_version)
    end
  end
end

#
# | RUBY_ENGINE | Implementation    |
# |:-----------:|:-----------------:|
# | <undefined> | MRI < 1.9         |
# | 'ruby'      | MRI >= 1.9 or REE |
# | 'jruby'     | JRuby             |
# | 'macruby'   | MacRuby           |
# | 'rbx'       | Rubinius          |
# | 'maglev'    | MagLev            |
# | 'ironruby'  | IronRuby          |
# | 'cardinal'  | Cardinal          |
#

INTERPRETER_MATRIX = {
  nil         => 'MRI < 1.9',
  'ruby'      => 'MRI >= 1.9 or REE',
  'jruby'     => 'JRuby',
  'macruby'   => 'MacRuby',
  'rbx'       => 'Rubinius',
  'maglev'    => 'MagLev',
  'ironruby'  => 'IronRuby',
  'cardinal'  => 'Cardinal'
}

def ruby_engine_and_version
  current_engine = Object.const_defined?(:RUBY_ENGINE) && RUBY_ENGINE
  current_version = Object.const_defined?(:RUBY_VERSION) && RUBY_VERSION

  [current_engine, current_version]
end
