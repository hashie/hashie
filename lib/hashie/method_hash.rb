module Hashie

  # MethodHash is a convenience class that will always allow you to access values of the hash via methods.
  # Any hashes that are nested or included in arrays will act as if they included Hashie::Extensions::MethodAccess
  # MethodHash will also honor default blocks passed to it (the same as ::Hash).
  #
  # == Examples of Automatic Method Access
  #
  #   hash = Hashie::MethodHash.new(:name => 'John Smith', :address => {:state => 'CA', :zip => '90210'}, :contacts => [{:name => 'Jane Smith', :phone => '1234567890'}, {:name => 'Jonny Smith'}])
  #   hash.name # => 'John Smith'
  #   hash.address.state # => 'CA'
  #   hash.contacts.last.name # => 'Jonny Smith'
  #
  # == Examples of Default Block
  #
  #   favorites = Hashie::MethodHash.new(:food => 'Pizza', :drink => 'Coffee') { 'Not Available' }
  #   favorites.food # => 'Pizza'
  #   favorites.color # => 'Not Available'
  #
  #   # if initialized with no block, #color will raise
  #   favorites = Hashie::MethodHash.new(:food => 'Pizza', :drink => 'Coffee')
  #   favoties.color # => undefined method `color' for {}:Hashie::MethodHash
  #
  #
  class MethodHash < ::Hash
    include Hashie::Extensions::MethodAccess
    include Hashie::Extensions::Coercion
    coerce_value ::Hash, MethodHash

    def initialize(hash = {}, &block)
      @default_block = block
      super(&block)
      hash.each_pair do |k,v|
        if v.kind_of?(Array)
          self[k] = v.map { |e| e.is_a?(::Hash) ? MethodHash.new(e) : e }
        else
          self[k] = v
        end
      end
    end

    def method_missing(*args, &block)
      if @default_block
        self[args.first] = @default_block.call(self, args.first)
      end
      super
    end
  end
end