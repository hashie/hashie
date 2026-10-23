# frozen_string_literal: true

begin
  require 'rails/railtie'

  module Hashie
    class Railtie < Rails::Railtie
      # Set the Hashie.logger to use Rails.logger when used with rails.
      initializer 'hashie.configure_logger', after: 'initialize_logger' do
        Hashie.logger = Rails.logger
      end

      initializer 'hashie.patch_hash_except', after: 'load_active_support' do
        if Rails::VERSION::MAJOR >= 6
          require 'hashie/extensions/active_support/core_ext/hash'
          Hashie::Mash.include Hashie::Extensions::ActiveSupport::CoreExt::Hash
        end
      end
    end
  end
rescue LoadError => e
  Hashie.logger.info("Hashie skipping railtie as #{e.message}")
end

# @!parse
#   module Hashie
#     # Integrates Hashie's logger and Mash exclusions with Rails.
#     #
#     # @example Run the Rails integration initializers
#     #   require 'logger'
#     #   require 'rails'
#     #   require 'hashie/railtie'
#     #   previous_rails_logger = Rails.logger
#     #   previous_hashie_logger = Hashie.logger
#     #   begin
#     #     Rails.logger = Logger.new(IO::NULL)
#     #     initializers = Hashie::Railtie.initializers.select { |item| item.name.start_with?('hashie.') }
#     #     initializers.each { |initializer| initializer.run(nil) }
#     #     Hashie.logger.equal?(Rails.logger) # => true
#     #     Hashie::Mash.new(name: 'Ada', age: 37).except(:age).to_h # => {'name' => 'Ada'}
#     #   ensure
#     #     Rails.logger = previous_rails_logger
#     #     Hashie.logger = previous_hashie_logger
#     #   end
#     class Railtie < Rails::Railtie
#     end
#   end
