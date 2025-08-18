# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module LDAP
        # attribute mapper to redact sensitive keys
        class AttributeMapper
          SENSITIVE_KEYS = %w[userPassword unicodePwd lmPassword ntPassword authPassword krbPrincipalKey sambaNTPassword sambaLMPassword].freeze

          def self.redact(_value)
            '[REDACTED]'
          end

          def self.map_json(json_string)
            parsed = JSON.parse(json_string)
            redacted = deep_map(parsed)
            JSON.generate(redacted)
          rescue JSON::ParserError
            json_string
          end

          def self.map(attributes)
            deep_map(attributes)
          end

          def self.deep_map(obj)
            case obj
            when Hash
              obj.each_with_object({}) do |(k, v), result|
                key_str = k.to_s
                result[k] = SENSITIVE_KEYS.include?(key_str) ? redact(v) : deep_map(v)
              end
            when Array
              # Special case: LDAP operation tuple like ["replace", "unicodePwd", ["value"]]
              if obj.size == 3 && obj[1].is_a?(String) && SENSITIVE_KEYS.include?(obj[1])
                [obj[0], obj[1], ['[REDACTED]']]
              else
                obj.map { |item| deep_map(item) }
              end
            when String
              map_json(obj)
            else
              obj
            end
          end
        end
      end
    end
  end
end
