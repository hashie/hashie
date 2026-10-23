# frozen_string_literal: true

# @example Multiple assertions with multiline setup
#   hash = {
#     abc: 'def'
#   }
#   Hashie.stringify_keys(hash) # => { 'abc' => 'def' }
#   hash # => { abc: 'def' }
#   'literal # => is not an assertion' # => 'literal # => is not an assertion'
#   'Résumé' #=> 'Résumé'
#   class ExampleHash < Hash; end
#   ExampleHash.superclass # => Hash
#
# @example An independent namespace
#   class ExampleHash < Array; end
#   ExampleHash.superclass # => Array
module ValidDocumentationExample
end
