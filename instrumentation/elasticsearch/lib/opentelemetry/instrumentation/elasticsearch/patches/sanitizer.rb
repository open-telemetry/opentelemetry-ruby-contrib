# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Elasticsearch
      module Patches
        # Replaces values in a hash, given a set of keys to match on.
        class Sanitizer
          class << self
            FILTERED = '?'
            DEFAULT_KEY_PATTERNS =
              %w[password passwd pwd secret *key *token* *session* *credit* *card* *auth* set-cookie].map! do |p|
                Regexp.new(p.gsub('*', '.*'))
              end

            def sanitize(query, key_patterns = [])
              patterns = DEFAULT_KEY_PATTERNS
              patterns += key_patterns if key_patterns
              sanitize!(DeepDup.dup(query), patterns)
            end

            private

            def sanitize!(obj, key_patterns)
              return obj unless obj.is_a?(Hash)

              obj.each_pair do |k, v|
                case v
                when Hash
                  sanitize!(v, key_patterns)
                else
                  next unless filter_key?(key_patterns, k)

                  obj[k] = FILTERED
                end
              end
            end

            def filter_key?(key_patterns, key)
              key_patterns.any? { |regex| regex.match(key) }
            end
          end
        end
      end
    end
  end
end
