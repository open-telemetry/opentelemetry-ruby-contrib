# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Elasticsearch
      # The Instrumentation class contains logic to detect and install the Elasticsearch instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('8.0.0')

        install do |config|
          convert_config(config)
          require_dependencies
          patch
        end

        present do
          !defined?(::Elastic::Transport::Client).nil?
        end

        compatible do
          # Versions < 8.0 of the elasticsearch client don't have the
          # Elastic::Transport namespace so we have to check that it's
          # present first.
          present? && gem_version >= MINIMUM_VERSION
        end

        def patch
          ::Elastic::Transport::Client.prepend(Patches::Client)
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :obfuscate, validate: %I[omit obfuscate include]
        option :sanitize_field_names, default: nil, validate: ->(v) { v.is_a?(String) || v.is_a?(Array) }

        private

        def convert_config(config)
          return unless (field_names = config[:sanitize_field_names])

          field_names = field_names.is_a?(String) ? field_names.split(',') : Array(field_names)
          config[:sanitize_field_names] = field_names.map { |p| WildcardPattern.new(p) }
        end

        def gem_version
          Gem::Version.new(::Elastic::Transport::VERSION)
        end

        def require_dependencies
          require_relative 'patches/client'
          require_relative 'patches/deep_dup'
          require_relative 'patches/sanitizer'
        end
      end
    end
  end
end
