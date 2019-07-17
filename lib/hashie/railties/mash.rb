
module Hashie
  class Mash < Hash
    def except(*keys)
      string_keys = keys.map { |key| convert_key(key) }
      slice(*self.keys - string_keys)
    end
  end
end
