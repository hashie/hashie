require 'hashie/version'

module Hashie
  autoload :Clash,              'hashie/clash'
  autoload :Dash,               'hashie/dash'
  autoload :Hash,               'hashie/hash'
  autoload :Mash,               'hashie/mash'
  autoload :Trash,              'hashie/trash'
  autoload :Rash,               'hashie/rash'

  module Extensions
    autoload :Coercion,          'hashie/extensions/coercion'
    autoload :DeepMerge,         'hashie/extensions/deep_merge'
    autoload :IgnoreUndeclared,  'hashie/extensions/ignore_undeclared'
    autoload :IndifferentAccess, 'hashie/extensions/indifferent_access'
    autoload :MergeInitializer,  'hashie/extensions/merge_initializer'
    autoload :MethodAccess,      'hashie/extensions/method_access'
    autoload :MethodQuery,       'hashie/extensions/method_access'
    autoload :MethodReader,      'hashie/extensions/method_access'
    autoload :MethodWriter,      'hashie/extensions/method_access'
    autoload :StringifyKeys,     'hashie/extensions/stringify_keys'
    autoload :SymbolizeKeys,     'hashie/extensions/symbolize_keys'
    autoload :DeepFetch,         'hashie/extensions/deep_fetch'
    autoload :DeepFind,          'hashie/extensions/deep_find'
    autoload :PrettyInspect,     'hashie/extensions/pretty_inspect'
    autoload :KeyConversion,     'hashie/extensions/key_conversion'
    autoload :MethodAccessWithOverride, 'hashie/extensions/method_access'

    module Parsers
      autoload :YamlErbParser, 'hashie/extensions/parsers/yaml_erb_parser'
    end

    module Dash
      autoload :IndifferentAccess, 'hashie/extensions/dash/indifferent_access'
    end

    module Mash
      autoload :SafeAssignment, 'hashie/extensions/mash/safe_assignment'
    end
  end

  class << self
    include Hashie::Extensions::StringifyKeys::ClassMethods
    include Hashie::Extensions::SymbolizeKeys::ClassMethods
  end
end
