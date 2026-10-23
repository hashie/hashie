# frozen_string_literal: true

module Hashie
  module Yard
    # Inspired by @maxlinc's proposal and prototype for hashie/hashie#158:
    # https://gist.github.com/maxlinc/19354152adf8555b158a
    class DashPropertyHandler < ::YARD::Handlers::Ruby::Base
      handles method_call(:property)
      namespace_only

      process do
        next unless scope == :instance && dash_namespace?
        next if statement.namespace && statement.namespace.source != 'self'

        name = property_name(statement.parameters(false).first)
        next unless name

        attributes = namespace.attributes[:instance][name] ||= { read: nil, write: nil }
        attributes[:read] = register_accessor(name, false)
        attributes[:write] = register_accessor(name, true)
        attributes.each_value { |object| add_metadata(object) }
      end

      private

      def dash_namespace?
        current = namespace
        visited = []
        while current.is_a?(::YARD::CodeObjects::ClassObject)
          return true if current.path == 'Hashie::Dash'
          return false if visited.include?(current.path)

          visited << current.path
          current = current.superclass
        end
        current && current.path == 'Hashie::Dash'
      end

      def property_name(node)
        return unless node

        name = case node.type
               when :symbol_literal
                 node.jump(:ident, :kw).source
               when :string_literal
                 node.jump(:string_content).source
               end
        name if name&.match?(/\A[a-zA-Z_]\w*[!?]?\z/)
      end

      def register_accessor(name, writer)
        method_name = writer ? "#{name}=" : name
        object = ::YARD::CodeObjects::MethodObject.new(namespace, method_name, :instance)
        object.parameters = writer ? [['value', nil]] : []
        register(object)
        object.docstring = fallback_docstring(name, writer) if object.docstring.blank?(false)
        object
      end

      def fallback_docstring(name, writer)
        if writer
          "Sets the value of #{name}.\n@param value the value to assign."
        else
          "Returns the value of #{name}."
        end
      end

      def add_metadata(object)
        options.each do |key, value|
          object["hashie_#{key}"] = value.source
          text = if key == 'required'
                   required_description(value.source)
                 else
                   "Default (Ruby source): `#{value.source}`."
                 end
          object.add_tag(::YARD::Tags::Tag.new(:note, text))
        end
      end

      def options
        arguments = statement.parameters(false)
        return {} unless arguments.size == 2

        hash = arguments.last
        return {} unless literal_options?(hash)

        hash.children.each_with_object({}) do |pair, result|
          key, value = pair.children
          name = option_name(key)
          result[name] = value if %w[default required].include?(name)
        end
      end

      def literal_options?(node)
        %i[hash list].include?(node.type) && node.children.all? do |child|
          child.type == :assoc && option_name(child.children.first)
        end
      end

      def option_name(node)
        case node.type
        when :label then node.source.delete_suffix(':')
        when :symbol_literal then property_name(node)
        end
      end

      def required_description(source)
        case source
        when 'true' then 'Required.'
        when 'false', 'nil' then 'Not required.'
        else "Required condition (Ruby source): `#{source}`."
        end
      end
    end
  end
end
