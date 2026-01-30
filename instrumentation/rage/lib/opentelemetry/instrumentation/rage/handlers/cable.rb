# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/semconv/incubating/code'
require 'opentelemetry/semconv/incubating/messaging'

module OpenTelemetry
  module Instrumentation
    module Rage
      module Handlers
        # The class customizes the initial Rack span used for WebSocket handshakes and wraps subsequent
        # Cable connection and action processing in spans linked to the handshake span.
        class Cable < ::Rage::Telemetry::Handler
          HANDSHAKE_CONTEXT = 'otel.rage.handshake_context'
          private_constant :HANDSHAKE_CONTEXT

          HANDSHAKE_LINK = 'otel.rage.handshake_link'
          private_constant :HANDSHAKE_LINK

          handle 'cable.websocket.handshake', with: :save_context

          handle 'cable.connection.process', with: :create_connection_span
          handle 'cable.action.process', with: :create_channel_span
          handle 'cable.stream.broadcast', with: :create_broadcast_span

          # @param env [Hash] the Rack env
          def self.save_context(env:)
            span = OpenTelemetry::Instrumentation::Rack.current_span
            return yield unless span.recording?

            request = ::Rack::Request.new(env)
            span.name = "#{request.request_method} #{request.path}"

            env[HANDSHAKE_CONTEXT] = OpenTelemetry::Context.current
            env[HANDSHAKE_LINK] = [OpenTelemetry::Trace::Link.new(span.context)]

            yield
          end

          # @param env [Hash] the Rack env
          # @param action [:connect, :disconnect] the name of the action being processed
          # @param connection [Rage::Cable::Connection] the connection instance
          def self.create_connection_span(env:, action:, connection:)
            handshake_context = env[HANDSHAKE_CONTEXT]
            handshake_link = env[HANDSHAKE_LINK]

            OpenTelemetry::Context.with_current(handshake_context) do
              attributes = {
                SemConv::Incubating::MESSAGING::MESSAGING_SYSTEM => 'rage.cable',
                SemConv::Incubating::MESSAGING::MESSAGING_DESTINATION_NAME => connection.class.name
              }

              kind = action == :connect ? :server : :internal

              span = Rage::Instrumentation.instance.tracer.start_root_span(
                "#{connection.class} #{action}",
                links: handshake_link,
                kind:,
                attributes:
              )

              OpenTelemetry::Trace.with_span(span) do
                result = yield

                if result.error?
                  span.record_exception(result.exception)
                  span.status = OpenTelemetry::Trace::Status.error
                end
              ensure
                span.finish
              end
            end
          end

          # @param env [Hash] the Rack env
          # @param action [Symbol] the name of the action being processed
          # @param channel [Rage::Cable::Channel] the channel instance
          def self.create_channel_span(env:, action:, channel:)
            handshake_context = env[HANDSHAKE_CONTEXT]
            handshake_link = env[HANDSHAKE_LINK]

            OpenTelemetry::Context.with_current(handshake_context) do
              attributes = {
                SemConv::Incubating::MESSAGING::MESSAGING_SYSTEM => 'rage.cable',
                SemConv::Incubating::MESSAGING::MESSAGING_DESTINATION_NAME => channel.class.name
              }

              attributes[SemConv::Incubating::MESSAGING::MESSAGING_OPERATION_TYPE] = 'process' unless action == :unsubscribed

              span_name = if action == :subscribed
                            "#{channel.class} subscribe"
                          elsif action == :unsubscribed
                            "#{channel.class} unsubscribe"
                          else
                            "#{channel.class} receive"
                          end

              kind = action == :unsubscribed ? :internal : :server

              span = Rage::Instrumentation.instance.tracer.start_root_span(
                span_name,
                links: handshake_link,
                kind:,
                attributes:
              )

              OpenTelemetry::Trace.with_span(span) do
                result = yield

                if result.error?
                  span.record_exception(result.exception)
                  span.status = OpenTelemetry::Trace::Status.error
                end
              ensure
                span.finish
              end
            end
          end

          # @param stream [String] the name of the stream
          def self.create_broadcast_span(stream:)
            attributes = {
              SemConv::Incubating::MESSAGING::MESSAGING_SYSTEM => 'rage.cable',
              SemConv::Incubating::MESSAGING::MESSAGING_OPERATION_TYPE => 'send',
              SemConv::Incubating::MESSAGING::MESSAGING_DESTINATION_NAME => stream
            }

            Rage::Instrumentation.instance.tracer.in_span('Rage::Cable broadcast', kind: :producer, attributes:) do |span|
              result = yield

              if result.error?
                span.record_exception(result.exception)
                span.status = OpenTelemetry::Trace::Status.error
              end
            end
          end
        end
      end
    end
  end
end
