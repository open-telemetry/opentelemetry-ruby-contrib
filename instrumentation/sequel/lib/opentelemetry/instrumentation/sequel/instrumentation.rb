# frozen_string_literal: true

require_relative 'database'
require_relative 'dataset'

module OpenTelemetry
  module Instrumentation
    module Sequel
      # The Instrumentation class contains logic to detect and install the Sequel
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('3.41')

        install do |_|
          patch_sequel_database
          patch_sequel_dataset
        end

        present do
          defined?(::Sequel)
        end

        compatible do
          defined?(::Sequel) && Gem.loaded_specs['sequel'].version >= MINIMUM_VERSION
        end

        option :service_name, default: 'sequel', validate: :string

        private

        def patch_sequel_database
          ::Sequel::Database.include(Database)
        end

        def patch_sequel_dataset
          ::Sequel::Dataset.include(Dataset)
        end
      end
    end
  end
end
