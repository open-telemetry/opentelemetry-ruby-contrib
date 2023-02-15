# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Elasticsearch
      module Patches
        class Sanitizer
          FILTERED = '?'
          DEFAULT_KEY_PATTERNS =
            %w[password passwd pwd secret *key *token* *session* *credit* *card* *auth* set-cookie].map! do |p|
              Regexp.new(p.gsub('*', '.*'))
            end

          def initialize(key_patterns = [])
            @key_patterns = DEFAULT_KEY_PATTERNS
            @key_patterns += key_patterns if key_patterns
          end

          def sanitize(query, obfuscate)
            sanitize!(DeepDup.dup(query), obfuscate)
          end

          private

          def sanitize!(obj, obfuscate)
            return unless obj.is_a?(Hash)

            obj.each_pair do |k, v|
              case v
              when Hash
                sanitize!(v, obfuscate)
              else
                next unless obfuscate
                next unless filter_key?(k)

                obj[k] = FILTERED
              end
            end
          end

          def filter_key?(key)
            @key_patterns.any? { |regex| regex.match(key) }
          end
        end
      end
    end
  end
end
