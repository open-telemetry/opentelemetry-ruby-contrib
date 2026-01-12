# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module LDAP
        # attribute mapper to redact keys which are not allowed
        class AttributeMapper
          LDAP_GENERAL_ATTRIBUTES = Set['attributes', 'base', 'filter', 'ignore_server_caps', 'left', 'op', 'operations',
                                        'paged_searches_supported', 'replace', 'right', 'scope'].freeze
          LDAP_OBJECT_ATTRIBUTES  = Set['accountExpires', 'codePage', 'countryCode', 'cn', 'description', 'displayName',
                                        'distinguishedName', 'dn', 'givenName', 'instanceType', 'mail', 'memberOf', 'name',
                                        'objectCategory', 'objectClass', 'pwdChangedTime', 'pwdLastSet', 'sAMAccountName',
                                        'userAccountControl', 'userPrincipalName'].freeze
          SPAN_ATTRIBUTES         = Set['exception.message', 'exception.stacktrace', 'exception.type', 'ldap.auth.method',
                                        'ldap.auth.username', 'ldap.error.message', 'ldap.operation.type', 'ldap.request.message',
                                        'ldap.response.status_code', 'ldap.tree.base', 'network.protocol.name',
                                        'network.protocol.version', 'network.transport', 'peer.service', 'server.address',
                                        'server.port'].freeze
          ALLOWED_KEYS = (LDAP_GENERAL_ATTRIBUTES + LDAP_OBJECT_ATTRIBUTES + SPAN_ATTRIBUTES).freeze

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
                result[k] = ALLOWED_KEYS.include?(key_str) ? deep_map(v) : redact(v)
              end
            when Array
              # Special case: LDAP operation tuple like ["replace", "unicodePwd", ["value"]]
              if obj.size == 3 && obj[1].is_a?(String) && !ALLOWED_KEYS.include?(obj[1])
                [obj[0], obj[1], ['[REDACTED]']]
              else
                obj.map { |item| deep_map(item) }
              end
            when String
              return obj unless obj.strip.start_with?('{', '[')

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
