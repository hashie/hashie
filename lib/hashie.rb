# frozen_string_literal: true

require 'hashie/logger'
require 'hashie/version'

# Hash-like objects and extensions for structured data.
#
# @example Access nested data using a Mash
#   Hashie::Mash.new(author: { name: 'Ada' }).author.name # => 'Ada'
module Hashie
  autoload :Clash,              'hashie/clash'
  autoload :Dash,               'hashie/dash'
  autoload :Hash,               'hashie/hash'
  autoload :Mash,               'hashie/mash'
  autoload :Trash,              'hashie/trash'
  autoload :Rash,               'hashie/rash'
  autoload :Array,              'hashie/array'
  autoload :Utils,              'hashie/utils'

  # Optional capabilities for Hash-like objects.
  #
  # @example Add recursive string keys to an ordinary hash
  #   hash = { count: 2 }.extend(Hashie::Extensions::StringifyKeys)
  #   hash.stringify_keys # => { 'count' => 2 }
  module Extensions
    autoload :BlockAccess,        'hashie/extensions/block_access'
    autoload :Coercion,           'hashie/extensions/coercion'
    autoload :KernelCoercion,     'hashie/extensions/kernel_coercion'
    autoload :DeepMerge,          'hashie/extensions/deep_merge'
    autoload :DeepMergeInitializer, 'hashie/extensions/deep_merge_initializer'
    autoload :IgnoreUndeclared,   'hashie/extensions/ignore_undeclared'
    autoload :IndifferentAccess,  'hashie/extensions/indifferent_access'
    autoload :MergeInitializer,   'hashie/extensions/merge_initializer'
    autoload :MethodAccess,       'hashie/extensions/method_access'
    autoload :MethodQuery,        'hashie/extensions/method_access'
    autoload :MethodReader,       'hashie/extensions/method_access'
    autoload :MethodWriter,       'hashie/extensions/method_access'
    autoload :Persistable,        'hashie/extensions/persistable'
    autoload :StringifyKeys,      'hashie/extensions/stringify_keys'
    autoload :SymbolizeKeys,      'hashie/extensions/symbolize_keys'
    autoload :DeepFetch,          'hashie/extensions/deep_fetch'
    autoload :DeepFind,           'hashie/extensions/deep_find'
    autoload :DeepLocate,         'hashie/extensions/deep_locate'
    autoload :DeepGrep,           'hashie/extensions/deep_grep'
    autoload :PrettyInspect,      'hashie/extensions/pretty_inspect'
    autoload :KeyConversion,      'hashie/extensions/key_conversion'
    autoload :MethodAccessWithOverride, 'hashie/extensions/method_access'
    autoload :StrictKeyAccess,    'hashie/extensions/strict_key_access'
    autoload :RubyVersion,        'hashie/extensions/ruby_version'
    autoload :RubyVersionCheck,   'hashie/extensions/ruby_version_check'

    # Parsers used when loading persisted hashes.
    #
    # @example Select the YAML parser without ERB evaluation
    #   Hashie::Extensions::Parsers::YamlParser.respond_to?(:perform) # => true
    module Parsers
      autoload :YamlParser, 'hashie/extensions/parsers/yaml_parser'
      autoload :YamlErbParser, 'hashie/extensions/parsers/yaml_erb_parser'
    end

    # Optional extensions for defined-property hashes.
    #
    # @example Allow string access to declared symbol properties
    #   klass = Class.new(Hashie::Dash) do
    #     include Hashie::Extensions::Dash::IndifferentAccess
    #     property :name
    #   end
    #   klass.new(name: 'Ada')['name'] # => 'Ada'
    module Dash
      autoload :IndifferentAccess, 'hashie/extensions/dash/indifferent_access'
      autoload :PropertyTranslation, 'hashie/extensions/dash/property_translation'
      autoload :Coercion, 'hashie/extensions/dash/coercion'
      autoload :Lazy, 'hashie/extensions/dash/lazy'
      autoload :PredefinedValues, 'hashie/extensions/dash/predefined_values'
    end

    # Optional extensions for method-accessible hashes.
    #
    # @example Generate accessors for existing keys
    #   mash = Hashie::Mash.new(name: 'Ada')
    #   mash.extend(Hashie::Extensions::Mash::DefineAccessors)
    #   mash.name # => 'Ada'
    module Mash
      autoload :KeepOriginalKeys, 'hashie/extensions/mash/keep_original_keys'
      autoload :PermissiveRespondTo, 'hashie/extensions/mash/permissive_respond_to'
      autoload :SafeAssignment, 'hashie/extensions/mash/safe_assignment'
      autoload :SymbolizeKeys, 'hashie/extensions/mash/symbolize_keys'
      autoload :DefineAccessors, 'hashie/extensions/mash/define_accessors'
      autoload :StrictKeyAccess, 'hashie/extensions/mash/strict_key_access'
      autoload :RequiredKeys, 'hashie/extensions/mash/required_keys'
      autoload :TransformKeys, 'hashie/extensions/mash/transform_keys'
      autoload :UnderscoreKeys, 'hashie/extensions/mash/underscore_keys'
    end

    # Optional extensions for arrays.
    #
    # @example Add Hashie-style inspection to an array
    #   klass = Class.new(::Array) { include Hashie::Extensions::Array::PrettyInspect }
    #   klass.new([1, 2]).inspect # => "#<#{klass} [1, 2]>"
    module Array
      autoload :PrettyInspect, 'hashie/extensions/array/pretty_inspect'
    end
  end

  class << self
    include Hashie::Extensions::StringifyKeys::ClassMethods
    include Hashie::Extensions::SymbolizeKeys::ClassMethods
  end

  require 'hashie/railtie' if defined?(::Rails)
end
