# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Redis
      module Patches
        module Stable
          # Module to prepend to Redis::Client for instrumentation
          module RedisV4Client
            MAX_STATEMENT_LENGTH = 500
            private_constant :MAX_STATEMENT_LENGTH

            def process(commands)
              return super unless instrumentation_config[:trace_root_spans] || OpenTelemetry::Trace.current_span.context.valid?

              host = options[:host]
              port = options[:port]

              attributes = {
                'db.system.name' => 'redis',
                'server.address' => host
              }

              attributes['server.port'] = port if port

              # db.namespace is the database index as a string (replaces db.redis.database_index in stable)
              attributes['db.namespace'] = options[:db].to_s unless options[:db].zero?
              attributes.merge!(OpenTelemetry::Instrumentation::Redis.attributes)

              unless instrumentation_config[:db_statement] == :omit
                parsed_commands = parse_commands(commands)
                parsed_commands = OpenTelemetry::Common::Utilities.truncate(parsed_commands, MAX_STATEMENT_LENGTH)
                parsed_commands = OpenTelemetry::Common::Utilities.utf8_encode(parsed_commands, binary: true)
                attributes['db.query.text'] = parsed_commands
              end

              span_name = if commands.length == 1
                            op_name = commands[0][0].to_s.upcase
                            attributes['db.operation.name'] = op_name
                            op_name
                          else
                            attributes['db.operation.name'] = 'PIPELINE'
                            attributes['db.operation.batch.size'] = commands.length
                            'PIPELINE'
                          end

              instrumentation_tracer.in_span(span_name, attributes: attributes, kind: :client) do |s|
                super.tap do |reply|
                  if reply.is_a?(::Redis::CommandError)
                    error_type = extract_error_type(reply)
                    s.set_attribute('error.type', error_type)
                    s.set_attribute('db.response.status_code', error_type)
                    s.record_exception(reply)
                    s.status = Trace::Status.error(reply.message)
                  end
                end
              end
            end

            private

            # Examples of commands received for parsing
            # Redis#queue     [[[:set, "v1", "0"]], [[:incr, "v1"]], [[:get, "v1"]]]
            # Redis#pipeline: [[:set, "v1", "0"], [:incr, "v1"], [:get, "v1"]]
            # Redis#hmset     [[:hmset, "hash", "f1", 1234567890.0987654]]
            # Redis#set       [[:set, "K", "x"]]
            def parse_commands(commands)
              commands.map do |command|
                # We are checking for the use of Redis#queue command, if we detect the
                # extra level of array nesting we return the first element so it
                # can be parsed.
                command = command[0] if command.is_a?(Array) && command[0].is_a?(Array)

                # If we receive an authentication request command
                # we want to short circuit parsing the commands
                # and return the obfuscated command
                return 'AUTH ?' if command[0] == :auth

                if instrumentation_config[:db_statement] == :obfuscate
                  command[0].to_s.upcase + (' ?' * (command.size - 1))
                else
                  command_copy = command.dup
                  command_copy[0] = command_copy[0].to_s.upcase
                  command_copy.join(' ')
                end
              end.join("\n")
            end

            def instrumentation_tracer
              Redis::Instrumentation.instance.tracer
            end

            def instrumentation_config
              Redis::Instrumentation.instance.config
            end

            def extract_error_type(error)
              # Redis errors start with an error prefix like ERR, WRONGTYPE, CLUSTERDOWN
              # Extract this prefix for db.response.status_code and error.type
              if error.message
                prefix = error.message.split.first
                return prefix if prefix && prefix == prefix.upcase && prefix.match?(/\A[A-Z]+\z/)
              end
              error.class.name
            end
          end
        end
      end
    end
  end
end
