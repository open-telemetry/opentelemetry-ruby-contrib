# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../test_helper'

describe OpenTelemetry::Instrumentation::AwsSdk do
  describe 'AwsSdk Plugin' do
    let(:instrumentation_gem_version) do
      OpenTelemetry::Instrumentation::AwsSdk::Instrumentation.instance.gem_version
    end
    let(:otel_semantic) { OpenTelemetry::SemanticConventions::Trace }
    let(:exporter) { EXPORTER }
    let(:span) { exporter.finished_spans.last }
    let(:span_attrs) do
      {
        'aws.region' => 'us-stubbed-1',
        otel_semantic::HTTP_STATUS_CODE => 200,
        otel_semantic::RPC_SYSTEM => 'aws-api'
      }
    end

    before do
      exporter.reset
    end

    describe 'Lambda' do
      let(:service_name) { 'Lambda' }
      let(:client) { Aws::Lambda::Client.new(stub_responses: true) }
      let(:expected_attrs) do
        span_attrs.tap do |attrs|
          attrs[otel_semantic::RPC_METHOD] = 'ListFunctions'
          attrs[otel_semantic::RPC_SERVICE] = service_name
        end
      end

      it 'creates a span with all the supplied parameters' do
        skip if TestHelper.telemetry_plugin?(service_name)

        client.list_functions

        _(span.name).must_equal('Lambda.ListFunctions')
        _(span.kind).must_equal(:client)
        TestHelper.match_span_attrs(expected_attrs, span, self)
      end

      it 'should have correct span attributes when error' do
        skip if TestHelper.telemetry_plugin?(service_name)

        client.stub_responses(:list_functions, 'NotFound')

        begin
          client.list_functions
        rescue Aws::Lambda::Errors::NotFound
          _(span.status.code).must_equal(2)
          _(span.events[0].name).must_equal('exception')
          _(span.attributes[otel_semantic::HTTP_STATUS_CODE]).must_equal(400)
        end
      end
    end

    describe 'SNS' do
      let(:service_name) { 'SNS' }
      let(:client) { Aws::SNS::Client.new(stub_responses: true) }
      let(:expected_attrs) do
        span_attrs.tap do |attrs|
          attrs[otel_semantic::RPC_METHOD] = 'Publish'
          attrs[otel_semantic::RPC_SERVICE] = service_name
          attrs[otel_semantic::MESSAGING_DESTINATION_KIND] = 'topic'
          attrs[otel_semantic::MESSAGING_DESTINATION] = 'TopicName'
          attrs[otel_semantic::MESSAGING_SYSTEM] = 'aws.sns'
        end
      end

      it 'creates a span with appropriate messaging attributes' do
        skip if TestHelper.telemetry_plugin?(service_name)

        client.publish(
          message: 'msg',
          topic_arn: 'arn:aws:sns:fake:123:TopicName'
        )

        _(span.name).must_equal('TopicName publish')
        _(span.kind).must_equal(:producer)
        TestHelper.match_span_attrs(expected_attrs, span, self)
      end

      it 'creates a span that includes a phone number' do
        # skip if using aws-sdk version before phone_number supported (v2.3.18)
        skip if Gem::Version.new('2.3.18') > instrumentation_gem_version
        skip if TestHelper.telemetry_plugin?(service_name)

        client.publish(message: 'msg', phone_number: '123456')

        _(span.name).must_equal('phone_number publish')
        _(span.attributes[otel_semantic::MESSAGING_DESTINATION]).must_equal('phone_number')
      end
    end

    describe 'SQS' do
      let(:service_name) { 'SQS' }
      let(:client) { Aws::SQS::Client.new(stub_responses: true) }
      let(:queue_url) { 'https://sqs.fake.amazonaws.com/1/QueueName' }
      let(:expected_base_attrs) do
        span_attrs.tap do |attrs|
          attrs[otel_semantic::RPC_SERVICE] = service_name
          attrs[otel_semantic::MESSAGING_DESTINATION_KIND] = 'queue'
          attrs[otel_semantic::MESSAGING_DESTINATION] = 'QueueName'
          attrs[otel_semantic::MESSAGING_SYSTEM] = 'aws.sqs'
          attrs[otel_semantic::MESSAGING_URL] = queue_url
        end
      end

      describe '#SendMessage' do
        let(:expected_attrs) do
          span_attrs.tap do |attrs|
            attrs[otel_semantic::RPC_METHOD] = 'SendMessage'
          end
        end

        it 'creates a span with appropriate messaging attributes' do
          skip if TestHelper.telemetry_plugin?(service_name)

          client.send_message(message_body: 'msg', queue_url: queue_url)

          _(span.name).must_equal('QueueName publish')
          _(span.kind).must_equal(:producer)
          TestHelper.match_span_attrs(expected_attrs, span, self)
        end
      end

      describe '#SendMessageBatch' do
        let(:expected_attrs) do
          expected_base_attrs.tap do |attrs|
            attrs[otel_semantic::RPC_METHOD] = 'SendMessageBatch'
          end
        end

        it 'creates a span with appropriate messaging attributes' do
          skip if TestHelper.telemetry_plugin?(service_name)

          client.send_message_batch(
            queue_url: queue_url,
            entries: [{ id: 'Message1', message_body: 'Body1' }]
          )

          _(span.name).must_equal('QueueName publish')
          _(span.kind).must_equal(:producer)
          TestHelper.match_span_attrs(expected_attrs, span, self)
        end
      end

      describe '#ReceiveMessage' do
        let(:expected_attrs) do
          expected_base_attrs.tap do |attrs|
            attrs[otel_semantic::RPC_METHOD] = 'ReceiveMessage'
            attrs[otel_semantic::MESSAGING_OPERATION] = 'receive'
          end
        end

        it 'creates a span with appropriate messaging attributes' do
          skip if TestHelper.telemetry_plugin?(service_name)

          client.receive_message(queue_url: queue_url)

          _(span.name).must_equal('QueueName receive')
          _(span.kind).must_equal(:consumer)
          TestHelper.match_span_attrs(expected_attrs, span, self)
        end
      end

      describe '#GetQueueUrl' do
        it 'creates a span with appropriate messaging attributes' do
          skip if TestHelper.telemetry_plugin?(service_name)

          client.get_queue_url(queue_name: 'queue-name')

          _(span.attributes['messaging.destination']).must_equal('unknown')
          _(span.attributes).wont_include('messaging.url')
        end
      end
    end

    describe 'DynamoDB' do
      let(:client) { Aws::DynamoDB::Client.new(stub_responses: true) }

      it 'creates a span with dynamodb-specific attribute' do
        skip if TestHelper.telemetry_plugin?('DynamoDB')

        client.list_tables

        _(span.attributes[otel_semantic::DB_SYSTEM]).must_equal('dynamodb')
      end
    end
  end
end
