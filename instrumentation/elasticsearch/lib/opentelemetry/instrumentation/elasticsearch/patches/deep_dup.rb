# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Elasticsearch
      module Patches
        # Makes a deep copy of an Array or Hash
        # NB: Not guaranteed to work well with complex objects, only simple Hash,
        # Array, String, Number, etc.
        class DeepDup
          def initialize(obj)
            @obj = obj
          end

          def dup
            deep_dup(@obj)
          end

          def self.dup(obj)
            new(obj).dup
          end

          private

          def deep_dup(obj)
            case obj
            when Hash then hash(obj)
            when Array then array(obj)
            else obj.dup
            end
          end

          def array(arr)
            arr.map { |obj| deep_dup(obj) }
          end

          def hash(hsh)
            result = hsh.dup

            hsh.each_pair do |key, value|
              result[key] = deep_dup(value)
            end

            result
          end
        end
      end
    end
  end
end
