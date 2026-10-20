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
      before { check_target_service(service_name) }
      let(:client) { Aws::Lambda::Client.new(stub_responses: true) }
      let(:expected_attrs) do
        span_attrs.tap do |attrs|
          attrs[otel_semantic::RPC_METHOD] = 'ListFunctions'
          attrs[otel_semantic::RPC_SERVICE] = service_name
        end
      end

      it 'creates a span with all the supplied parameters' do
        client.list_functions

        _(span.name).must_equal('Lambda.ListFunctions')
        _(span.kind).must_equal(:client)
        TestHelper.match_span_attrs(expected_attrs, span, self)
      end

      it 'should have correct span attributes when error' do
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
      before { check_target_service(service_name) }
      let(:client) { Aws::SNS::Client.new(stub_responses: true) }
      let(:topic_arn_key) { TestHelper::SNS_TOPIC_ARN_ATTRIBUTE }
      let(:subscription_arn) { 'arn:aws:sns:fake:123:TopicName:00000000-1111-2222-3333-444444444444' }
      let(:longest_topic_name) { 'a' * 256 }
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
        client.publish(
          message: 'msg',
          topic_arn: 'arn:aws:sns:fake:123:TopicName'
        )

        _(span.name).must_equal('TopicName publish')
        _(span.kind).must_equal(:producer)
        TestHelper.match_span_attrs(expected_attrs, span, self)
      end

      it 'records the full topic arn' do
        client.publish(
          message: 'msg',
          topic_arn: 'arn:aws:sns:fake:123:TopicName'
        )

        _(span.attributes[topic_arn_key]).must_equal('arn:aws:sns:fake:123:TopicName')
      end

      it 'records a topic arn supplied through target arn' do
        target_arn = 'arn:aws:sns:us-east-1:123456789012:TopicName'

        client.publish(message: 'msg', target_arn: target_arn)

        _(span.attributes[topic_arn_key]).must_equal(target_arn)
      end

      it 'records a fifo topic arn' do
        topic_arn = 'arn:aws:sns:fake:123:My_Topic-1.fifo'

        client.publish(message: 'msg', topic_arn: topic_arn)

        _(span.attributes[topic_arn_key]).must_equal(topic_arn)
      end

      it 'records a topic name at the length limit' do
        topic_arn = "arn:aws:sns:fake:123:#{longest_topic_name}"

        client.publish(message: 'msg', topic_arn: topic_arn)

        _(span.attributes[topic_arn_key]).must_equal(topic_arn)
      end

      it 'prefers a populated topic arn over a target arn' do
        client.publish(
          message: 'msg',
          topic_arn: 'arn:aws:sns:fake:123:FromTopicArn',
          target_arn: 'arn:aws:sns:fake:123:FromTargetArn'
        )

        _(span.attributes[topic_arn_key]).must_equal('arn:aws:sns:fake:123:FromTopicArn')
        _(span.attributes[otel_semantic::MESSAGING_DESTINATION]).must_equal('FromTopicArn')
      end

      it 'does not fall back to target arn when the populated topic arn is not a topic' do
        client.publish(
          message: 'msg',
          topic_arn: subscription_arn,
          target_arn: 'arn:aws:sns:fake:123:FromTargetArn'
        )

        _(span.attributes).wont_include(topic_arn_key)
        _(span.attributes[otel_semantic::MESSAGING_DESTINATION])
          .must_equal('00000000-1111-2222-3333-444444444444')
      end

      it 'uses target arn when topic arn is empty' do
        target_arn = 'arn:aws:sns:fake:123:FromTargetArn'

        client.publish(message: 'msg', topic_arn: '', target_arn: target_arn)

        _(span.attributes[topic_arn_key]).must_equal(target_arn)
        _(span.attributes[otel_semantic::MESSAGING_DESTINATION]).must_equal('FromTargetArn')
      end

      it 'uses target arn when topic arn is nil' do
        target_arn = 'arn:aws:sns:fake:123:FromTargetArn'

        client.publish(message: 'msg', topic_arn: nil, target_arn: target_arn)

        _(span.attributes[topic_arn_key]).must_equal(target_arn)
        _(span.attributes[otel_semantic::MESSAGING_DESTINATION]).must_equal('FromTargetArn')
      end

      it 'records an unknown destination when every destination parameter is empty' do
        client.publish(message: 'msg', topic_arn: '', target_arn: '')

        _(span.attributes).wont_include(topic_arn_key)
        _(span.attributes[otel_semantic::MESSAGING_DESTINATION]).must_equal('unknown')
      end

      it 'does not report a platform endpoint as a topic' do
        target_arn = 'arn:aws:sns:fake:123:endpoint/APNS/MyApp/00000000-1111-2222-3333-444444444444'

        client.publish(message: 'msg', target_arn: target_arn)

        _(span.attributes).wont_include(topic_arn_key)
        _(span.attributes[otel_semantic::MESSAGING_DESTINATION])
          .must_equal('endpoint/APNS/MyApp/00000000-1111-2222-3333-444444444444')
      end

      it 'does not report a platform application as a topic' do
        target_arn = 'arn:aws:sns:fake:123:app/APNS/MyApp'

        client.publish(message: 'msg', target_arn: target_arn)

        _(span.attributes).wont_include(topic_arn_key)
        _(span.attributes[otel_semantic::MESSAGING_DESTINATION]).must_equal('app/APNS/MyApp')
      end

      it 'does not report a subscription arn as a topic' do
        client.publish(message: 'msg', topic_arn: subscription_arn)

        _(span.attributes).wont_include(topic_arn_key)
      end

      it 'does not report a subscription arn supplied through target arn as a topic' do
        client.publish(message: 'msg', target_arn: subscription_arn)

        _(span.attributes).wont_include(topic_arn_key)
      end

      it 'does not report an arn from another service as a topic' do
        client.publish(message: 'msg', topic_arn: 'arn:aws:sqs:fake:123:QueueName')

        _(span.attributes).wont_include(topic_arn_key)
      end

      it 'does not report a malformed arn as a topic' do
        client.publish(message: 'msg', topic_arn: 'arn:aws:sns:fake:123')

        _(span.attributes).wont_include(topic_arn_key)
      end

      it 'does not report a topic name holding a space as a topic' do
        client.publish(message: 'msg', topic_arn: 'arn:aws:sns:fake:123:Topic Name')

        _(span.attributes).wont_include(topic_arn_key)
        _(span.attributes[otel_semantic::MESSAGING_DESTINATION]).must_equal('Topic Name')
      end

      it 'does not report a phone number resource as a topic' do
        client.publish(message: 'msg', topic_arn: 'arn:aws:sns:fake:123:+15551234567')

        _(span.attributes).wont_include(topic_arn_key)
      end

      it 'does not report a topic name over the length limit as a topic' do
        client.publish(message: 'msg', topic_arn: "arn:aws:sns:fake:123:#{longest_topic_name}a")

        _(span.attributes).wont_include(topic_arn_key)
      end

      it 'creates a span that includes a phone number' do
        # skip if using aws-sdk version before phone_number supported (v2.3.18)
        skip if Gem::Version.new('2.3.18') > instrumentation_gem_version

        client.publish(message: 'msg', phone_number: '123456')

        _(span.name).must_equal('phone_number publish')
        _(span.attributes[otel_semantic::MESSAGING_DESTINATION]).must_equal('phone_number')
      end

      it 'does not record an arn or the phone number for a phone number publish' do
        skip if Gem::Version.new('2.3.18') > instrumentation_gem_version

        client.publish(message: 'msg', phone_number: '123456')

        _(span.attributes).wont_include(topic_arn_key)
        _(span.attributes.values.grep(/123456/)).must_be_empty
      end

      it 'does not record a topic arn for another SNS operation' do
        client.subscribe(
          topic_arn: 'arn:aws:sns:fake:123:TopicName',
          protocol: 'email',
          endpoint: 'person@example.com'
        )

        subscribe_span = exporter.finished_spans.find { |finished| finished.name == 'SNS.Subscribe' }
        _(subscribe_span).wont_be_nil
        _(subscribe_span.attributes).wont_include(topic_arn_key)
      end
    end

    describe 'SQS' do
      let(:service_name) { 'SQS' }
      before { check_target_service(service_name) }
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
          client.receive_message(queue_url: queue_url)

          _(span.name).must_equal('QueueName receive')
          _(span.kind).must_equal(:consumer)
          TestHelper.match_span_attrs(expected_attrs, span, self)
        end
      end

      describe '#GetQueueUrl' do
        it 'creates a span with appropriate messaging attributes' do
          client.get_queue_url(queue_name: 'queue-name')

          _(span.attributes['messaging.destination']).must_equal('unknown')
          _(span.attributes).wont_include('messaging.url')
        end
      end
    end

    describe 'DynamoDB' do
      let(:service_name) { 'DynamoDB' }
      before { check_target_service(service_name) }
      let(:client) { Aws::DynamoDB::Client.new(stub_responses: true) }

      describe 'old semconv' do
        before do
          skip unless TestHelper.semconv_old?
        end

        it 'creates a span with old dynamodb-specific attributes' do
          client.list_tables

          _(span.attributes[otel_semantic::DB_SYSTEM]).must_equal('dynamodb')
          _(span.attributes).wont_include('db.system.name')
          _(span.attributes).wont_include('db.operation.name')
          _(span.attributes).wont_include('db.collection.name')
        end
      end

      describe 'stable semconv' do
        before do
          skip unless TestHelper.semconv_stable?
        end

        it 'creates a span with stable dynamodb-specific attributes' do
          client.list_tables

          _(span.attributes['db.system.name']).must_equal('aws.dynamodb')
          _(span.attributes['db.operation.name']).must_equal('ListTables')
          _(span.attributes).wont_include(otel_semantic::DB_SYSTEM)
          _(span.attributes).wont_include('db.collection.name')
        end

        it 'includes db.collection.name when table_name is present' do
          client.describe_table(table_name: 'TestTable')

          _(span.attributes['db.system.name']).must_equal('aws.dynamodb')
          _(span.attributes['db.operation.name']).must_equal('DescribeTable')
          _(span.attributes['db.collection.name']).must_equal('TestTable')
        end
      end

      describe 'dup semconv' do
        before do
          skip unless TestHelper.semconv_dup?
        end

        it 'creates a span with both old and stable dynamodb-specific attributes' do
          client.list_tables

          _(span.attributes[otel_semantic::DB_SYSTEM]).must_equal('dynamodb')
          _(span.attributes['db.system.name']).must_equal('aws.dynamodb')
          _(span.attributes['db.operation.name']).must_equal('ListTables')
          _(span.attributes).wont_include('db.collection.name')
        end

        it 'includes db.collection.name when table_name is present' do
          client.describe_table(table_name: 'TestTable')

          _(span.attributes[otel_semantic::DB_SYSTEM]).must_equal('dynamodb')
          _(span.attributes['db.system.name']).must_equal('aws.dynamodb')
          _(span.attributes['db.operation.name']).must_equal('DescribeTable')
          _(span.attributes['db.collection.name']).must_equal('TestTable')
        end
      end
    end

    def check_target_service(service_name)
      skip if TestHelper.telemetry_plugin?(service_name)
      skip unless TestHelper.testing_service?(service_name)
    end
  end
end
