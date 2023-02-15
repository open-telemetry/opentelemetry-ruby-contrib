# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Elasticsearch
      # The Instrumentation class contains logic to detect and install the Elasticsearch instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base

        install do |_config|
          require_dependencies
          patch
        end

        present do
          !defined?(::Elastic::Transport::Client).nil?
        end

        def patch
          ::Elastic::Transport::Client.prepend(Patches::Client)
        end

        option :peer_service, default: nil, validate: :string
        option :db_statement, default: :obfuscate, validate: %I[omit obfuscate include]
        option :sanitize_field_names, default: [], validate: :array

        private

        def require_dependencies
          require_relative 'patches/client'
          require_relative 'patches/deep_dup'
          require_relative 'patches/sanitizer'
        end
      end
    end
  end
end
