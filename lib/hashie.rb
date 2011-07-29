module Hashie
  autoload :Clash,          'hashie/clash'
  autoload :Dash,           'hashie/dash'
  autoload :Hash,           'hashie/hash'
  autoload :HashExtensions, 'hashie/hash_extensions'
  autoload :Mash,           'hashie/mash'
  autoload :PrettyInspect,  'hashie/hash_extensions'
  autoload :Trash,          'hashie/trash'

  module Extensions
    autoload :Coercion, 'hashie/extensions/coercion'
  end
end
