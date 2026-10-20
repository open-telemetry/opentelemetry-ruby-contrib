# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module AwsSdk
      # An utility class to help SQS/SNS-related span attributes/context injection
      class MessagingHelper
        SUPPORTED_SERVICES = %w[SQS SNS].freeze
        class << self
          SQS_SEND_MESSAGE = 'SQS.SendMessage'
          SQS_SEND_MESSAGE_BATCH = 'SQS.SendMessageBatch'
          SQS_RECEIVE_MESSAGE = 'SQS.ReceiveMessage'
          SNS_PUBLISH = 'SNS.Publish'
          SEND_MESSAGE_CLIENT_METHODS = [SQS_SEND_MESSAGE, SQS_SEND_MESSAGE_BATCH, SNS_PUBLISH].freeze
          SNS_TOPIC_ARN_ATTRIBUTE = 'aws.sns.topic.arn'
          # A topic name is 1 to 256 characters of letters, digits, hyphens and
          # underscores, and a first-in-first-out topic ends in the `.fifo`
          # suffix, which counts towards that same limit. The leading bound
          # rejects a longer name, and the character set rejects a space, a
          # control character, a slash, and the `+` that starts a phone number.
          SNS_TOPIC_NAME_PATTERN = /(?=.{1,256}\z)[A-Za-z0-9_-]+(?:\.fifo)?/
          # A topic ARN is the six ARN parts, `sns` as the service and a bare
          # topic name as the resource. A subscription ARN adds a seventh colon
          # separated part, and platform application and endpoint ARNs put
          # slashes in the resource, so neither of those is a topic.
          SNS_TOPIC_ARN_PATTERN = /\Aarn:[a-z0-9-]+:sns:[a-z0-9-]+:\d+:#{SNS_TOPIC_NAME_PATTERN}\z/

          def supported_services
            SUPPORTED_SERVICES
          end

          def queue_name(context)
            params = context.params
            destination_name(params, sns_destination_arn(params))
          end

          def span_name(context, client_method)
            case client_method
            when SQS_SEND_MESSAGE, SQS_SEND_MESSAGE_BATCH, SNS_PUBLISH
              "#{client_method}.#{queue_name(context)}.Publish"
            when SQS_RECEIVE_MESSAGE
              "#{client_method}.#{queue_name(context)}.Receive"
            else
              client_method
            end
          end

          def legacy_span_name(context, client_method)
            case client_method
            when SQS_SEND_MESSAGE, SQS_SEND_MESSAGE_BATCH, SNS_PUBLISH
              "#{MessagingHelper.queue_name(context)} publish"
            when SQS_RECEIVE_MESSAGE
              "#{MessagingHelper.queue_name(context)} receive"
            else
              client_method
            end
          end

          def apply_span_attributes(context, attrs, client_method, service_id)
            case service_id
            when 'SQS'
              apply_sqs_attributes(attrs, context, client_method)
            when 'SNS'
              apply_sns_attributes(attrs, context, client_method)
            end
          end

          def span_kind(client_method)
            case client_method
            when SQS_SEND_MESSAGE, SQS_SEND_MESSAGE_BATCH, SNS_PUBLISH
              OpenTelemetry::Trace::SpanKind::PRODUCER
            when SQS_RECEIVE_MESSAGE
              OpenTelemetry::Trace::SpanKind::CONSUMER
            else
              OpenTelemetry::Trace::SpanKind::CLIENT
            end
          end

          def inject_context_if_supported(context, client_method, service_id)
            if HandlerHelper.instrumentation_config[:inject_messaging_context] &&
               SUPPORTED_SERVICES.include?(service_id)
              inject_context(context, client_method)
            end
          end

          def inject_context(context, client_method)
            return unless SEND_MESSAGE_CLIENT_METHODS.include?(client_method)

            if client_method == SQS_SEND_MESSAGE_BATCH
              context.params[:entries].each do |entry|
                entry[:message_attributes] ||= {}
                OpenTelemetry.propagation.inject(entry[:message_attributes], setter: MessageAttributeSetter)
              end
            else
              context.params[:message_attributes] ||= {}
              OpenTelemetry.propagation.inject(context.params[:message_attributes], setter: MessageAttributeSetter)
            end
          end

          private

          def apply_sqs_attributes(attributes, context, client_method)
            attributes[SemanticConventions::Trace::MESSAGING_SYSTEM] = 'aws.sqs'
            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION_KIND] = 'queue'
            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION] = queue_name(context)
            attributes[SemanticConventions::Trace::MESSAGING_URL] = context.params[:queue_url] if context.params[:queue_url]
            attributes[SemanticConventions::Trace::MESSAGING_OPERATION] = 'receive' if client_method == SQS_RECEIVE_MESSAGE
          end

          # Records the full topic ARN without changing the existing
          # destination name. One selected parameter backs both, so they always
          # describe the same destination, and selecting it once keeps publish
          # from classifying the same value twice.
          def apply_sns_attributes(attributes, context, client_method)
            attributes[SemanticConventions::Trace::MESSAGING_SYSTEM] = 'aws.sns'
            return unless client_method == SNS_PUBLISH

            params = context.params
            arn = sns_destination_arn(params)

            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION_KIND] = 'topic'
            attributes[SemanticConventions::Trace::MESSAGING_DESTINATION] = destination_name(params, arn)
            attributes[SNS_TOPIC_ARN_ATTRIBUTE] = arn if arn && SNS_TOPIC_ARN_PATTERN.match?(arn)
          end

          # Names the destination from an already selected ARN, so a caller
          # needing both the name and the ARN selects once. An SNS destination
          # is named by the last colon separated ARN segment.
          def destination_name(params, arn)
            if arn
              name = arn.split(':')[-1]
              return name if name
            end

            return 'phone_number' if params[:phone_number]

            queue_url = params[:queue_url]
            return queue_url.split('/')[-1] if queue_url

            'unknown'
          end

          # Selects the one parameter that carries the publish destination.
          # `TopicArn` wins when it holds a value, and a missing or empty
          # parameter counts as absent, so a populated `TopicArn` is never
          # abandoned for a `TargetArn` naming somewhere else. The destination
          # name and the topic ARN attribute both read this one selection,
          # which is what keeps them describing the same destination. Takes no
          # block and builds no array, because publish is a hot path.
          def sns_destination_arn(params)
            topic_arn = params[:topic_arn]
            return topic_arn if topic_arn.is_a?(String) && !topic_arn.empty?

            target_arn = params[:target_arn]
            return target_arn if target_arn.is_a?(String) && !target_arn.empty?

            nil
          end
        end
      end
    end
  end
end
