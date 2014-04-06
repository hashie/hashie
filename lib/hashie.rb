module Hashie
  autoload :Clash,          'hashie/clash'
  autoload :Dash,           'hashie/dash'
  autoload :Hash,           'hashie/hash'
  autoload :HashExtensions, 'hashie/hash_extensions'
  autoload :Mash,           'hashie/mash'
  autoload :PrettyInspect,  'hashie/hash_extensions'
  autoload :Trash,          'hashie/trash'
  autoload :Rash,           'hashie/rash'

  module Extensions
    autoload :Coercion,          'hashie/extensions/coercion'
    autoload :DeepMerge,         'hashie/extensions/deep_merge'
    autoload :KeyConversion,     'hashie/extensions/key_conversion'
    autoload :IgnoreUndeclared,  'hashie/extensions/ignore_undeclared'
    autoload :IndifferentAccess, 'hashie/extensions/indifferent_access'
    autoload :MergeInitializer,  'hashie/extensions/merge_initializer'
    autoload :MethodAccess,      'hashie/extensions/method_access'
    autoload :MethodQuery,       'hashie/extensions/method_access'
    autoload :MethodReader,      'hashie/extensions/method_access'
    autoload :MethodWriter,      'hashie/extensions/method_access'
    autoload :StringifyKeys,     'hashie/extensions/key_conversion'
    autoload :SymbolizeKeys,     'hashie/extensions/key_conversion'
    autoload :DeepFetch,         'hashie/extensions/deep_fetch'
  end
end
