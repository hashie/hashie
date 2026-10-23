# frozen_string_literal: true

# @example Only public API documentation needs coverage
#   1 + 1 # => 2
class PrivateDocumentationExample
  # @api private
  class Internal
    def implementation_detail; end
  end

  # @private
  def hidden; end

  def legacy_internal; end # :nodoc:

  private

  def private_method; end
end
