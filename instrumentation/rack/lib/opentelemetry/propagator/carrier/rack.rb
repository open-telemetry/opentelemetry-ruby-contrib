# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Propagator
    module Carrier
      # Contains propagation helpers for reading context from a Rack environment.
      module Rack
        extend self

        # The EnvGetter class provides common methods for reading
        # keys from a rack environment. It abstracts away the rack-normalization
        # process so that keys can be looked up without having to transform them
        # first. With this class you can get +traceparent+ instead of
        # +HTTP_TRACEPARENT+
        class EnvGetter
          # Converts key into a rack-normalized key and reads it from the carrier.
          # Useful for extract operations.
          def get(carrier, key)
            carrier[to_rack_key(key)] || carrier[key]
          end

          # Reads all keys from a carrier and converts them from the rack-normalized
          # form to the original. The resulting keys will be lowercase and
          # underscores will be replaced with dashes.
          def keys(carrier)
            carrier.keys.map { |k| from_rack_key(k) }
          end

          private

          def to_rack_key(key)
            ret = "HTTP_#{key}"
            ret.tr!('-', '_')
            ret.upcase!
            ret
          end

          def from_rack_key(key)
            start = key.start_with?('HTTP_') ? 5 : 0
            ret = key[start..]
            ret.tr!('_', '-')
            ret.downcase!
            ret
          end
        end

        ENV_GETTER = EnvGetter.new
        private_constant :ENV_GETTER

        # Returns an {EnvGetter} instance suitable for reading values from a
        # Rack environment.
        def env_getter
          ENV_GETTER
        end
      end
    end
  end
end
