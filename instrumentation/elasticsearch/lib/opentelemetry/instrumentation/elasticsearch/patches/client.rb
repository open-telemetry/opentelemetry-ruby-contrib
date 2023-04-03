# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Elasticsearch
      module Patches
        NAME_FORMAT = '%s %s'
        IP_TCP = 'ip_tcp'

        # Module to prepend to Elastic::Transport::Client for instrumentation
        module Client
          # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          def perform_request(method, path, *args, &block)
            config = Elasticsearch::Instrumentation.instance.config
            attributes = {
              'db.system' => 'elasticsearch',
              # TODO: should we set db.name?
              # 'db.name' => database_name,
              'db.operation' => method,
              # TODO: is this true for all elasticsearch client requests?
              'net.transport' => IP_TCP,
              'elasticsearch.method' => method
              # TODO: set other elasticsearch custom attributes, based on spec
            }
            attributes['peer.service'] = config[:peer_service] if config[:peer_service]
            attributes['elasticsearch.params'] = args&.[](0).to_json if args&.[](0)

            # We can only be sure of the host info if there is one host.
            # Otherwise, the host will be selected further down the call stack.
            if (host = @hosts.size == 1 && @hosts[0])
              attributes['net.peer.name'] = host[:host]
              attributes['net.peer.port'] = host[:port]
            end

            body = args&.[](1)
            omit = config[:db_statement] == :omit
            sanitize = config[:db_statement] == :sanitize
            unless omit
              body = Sanitizer.sanitize(body, config[:sanitize_field_names]) if sanitize
              body = body.to_json if body && !body.is_a?(String)
              attributes['db.statement'] = body
            end

            attributes.compact!

            if config[:capture_es_spans]
              tracer.in_span(format(NAME_FORMAT, method, path), attributes: attributes, kind: :client) do
                super
              end
            else
              OpenTelemetry::Common::HTTP::ClientContext.with_attributes(attributes) do
                super
              end
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

          def tracer
            Elasticsearch::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
