# frozen_string_literal: true

module YardExamples
  class Person < Hashie::Dash
    # The person's name.
    # @return [String] a display name
    property :name, required: true
    property :age, default: 3, required: false
    property :enabled, :default => false, :required => nil
    self.property 'nickname', { default: 'anonymous' }
    property :token, default: -> { raise 'must not execute defaults' }, required: :needs_token?
    property :unsafe, default: raise('must not evaluate source'),
                      required: -> { raise 'must not execute conditions' }
    property :unknown, default: 1, **options
    property :dynamic_key, default: 1, option_name => 2
    property :dynamic_options, options
    property dynamic_name
    property "interpolated_#{raise 'must not interpolate source'}"
    unrelated.property :not_ours

    def example
      property :not_a_declaration
    end

    class << self
      property :not_an_instance_property
    end
  end

  class Child < Person
    property :child
  end

  class Grandchild < Child
    property :grandchild
  end

  class Other
    property :not_a_dash
  end

  class Unresolved < MissingBase
    property :not_discoverable
  end

  class Cycle < Cycle
    property :not_a_dash
  end

  module NotAClass
    property :not_a_class
  end
end
