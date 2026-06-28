# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../command_serializer'

module OpenTelemetry
  module Instrumentation
    module Mongo
      module Subscribers
        module Stable
          # Event handler class for Mongo Ruby driver (stable semantic conventions)
          class Subscriber
            THREAD_KEY = :__opentelemetry_mongo_spans__

            def started(event)
              # start a trace and store it in the current thread; using the `operation_id`
              # is safe since it's a unique id used to link events together. Also only one
              # thread is involved in this execution so thread-local storage should be safe. Reference:
              # https://github.com/mongodb/mongo-ruby-driver/blob/master/lib/mongo/monitoring.rb#L70
              # https://github.com/mongodb/mongo-ruby-driver/blob/master/lib/mongo/monitoring/publishable.rb#L38-L56

              collection = get_collection(event.command)

              attributes = {
                'db.system.name' => 'mongodb',
                'db.namespace' => event.database_name,
                'db.operation.name' => event.command_name,
                'server.address' => event.address.host,
                'server.port' => event.address.port
              }

              config = Mongo::Instrumentation.instance.config
              omit = config[:db_statement] == :omit
              obfuscate = config[:db_statement] == :obfuscate
              attributes['db.query.text'] = CommandSerializer.new(event.command, obfuscate).serialize unless omit
              attributes['db.collection.name'] = collection if collection
              attributes.compact!

              span = tracer.start_span(span_name(collection, event.command_name), attributes: attributes, kind: :client)
              set_span(event, span)
            end

            def failed(event)
              finish_event('failed', event) do |span|
                if event.is_a?(::Mongo::Monitoring::Event::CommandFailed)
                  error_type = extract_error_type(event)
                  span.set_attribute('error.type', error_type)
                  status_code = event.failure['code']
                  span.set_attribute('db.response.status_code', status_code.to_s) if status_code
                  span.add_event('exception',
                                 attributes: {
                                   'exception.type' => 'CommandFailed',
                                   'exception.message' => event.message
                                 })
                  span.status = OpenTelemetry::Trace::Status.error(event.message)
                end
              end
            end

            def succeeded(event)
              finish_event('succeeded', event)
            end

            private

            def finish_event(name, event)
              span = get_span(event)
              return unless span

              yield span if block_given?
            rescue StandardError => e
              OpenTelemetry.logger.debug("error when handling MongoDB '#{name}' event: #{e}")
            ensure
              # finish span to prevent leak and remove it from thread storage
              span&.finish
              clear_span(event)
            end

            def span_name(collection, command_name)
              return command_name unless collection

              "#{command_name} #{collection}"
            end

            def get_collection(command)
              collection = command.values.first
              collection if collection.is_a?(String)
            end

            def get_span(event)
              Thread.current[THREAD_KEY]&.[](event.request_id)
            end

            def set_span(event, span)
              Thread.current[THREAD_KEY] ||= {}
              Thread.current[THREAD_KEY][event.request_id] = span
            end

            def clear_span(event)
              Thread.current[THREAD_KEY]&.delete(event.request_id)
            end

            def extract_error_type(event)
              event.failure['codeName'] || 'CommandFailed'
            end

            def tracer
              Mongo::Instrumentation.instance.tracer
            end
          end
        end
      end
    end
  end
end
