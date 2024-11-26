# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../test_helper'

describe OpenTelemetry::Instrumentation::AwsSdk do
  describe 'Telemetry plugin' do
    let(:instrumentation_gem_version) do
      OpenTelemetry::Instrumentation::AwsSdk::Instrumentation.instance.gem_version
    end
    let(:otel_semantic) { OpenTelemetry::SemanticConventions::Trace }
    let(:exporter) { EXPORTER }
    let(:spans) { exporter.finished_spans }
    let(:otel_provider) { Aws::Telemetry::OTelProvider.new }
    let(:stub_span) { spans.find { |s| s.name == 'Handler.StubResponses' } }
    let(:client_attrs) do
      {
        'aws.region' => 'us-stubbed-1',
        otel_semantic::CODE_NAMESPACE => 'Aws::Plugins::Telemetry',
        otel_semantic::RPC_SYSTEM => 'aws-api'
      }
    end

    let(:stub_attrs) do
      {
        'http.status_code' => '200',
        'net.protocol.name' => 'http',
        'net.protocol.version' => '1.1'
      }
    end

    before do
      exporter.reset
    end

    describe 'Lambda' do
      let(:service_name) { 'Lambda' }
      let(:service_uri) do
        'https://lambda.us-east-1.amazonaws.com/2015-03-31/functions/'
      end
      let(:client) do
        Aws::Lambda::Client.new(
          telemetry_provider: otel_provider,
          stub_responses: true
        )
      end
      let(:client_span) { spans.find { |s| s.name == 'Lambda.ListFunctions' } }
      let(:internal_span) { spans.find { |s| s.name == 'Handler.NetHttp' } }

      let(:expected_client_attrs) do
        client_attrs.tap do |attrs|
          attrs[otel_semantic::CODE_FUNCTION] = 'list_functions'
          attrs[otel_semantic::RPC_METHOD] = 'ListFunctions'
          attrs[otel_semantic::RPC_SERVICE] = service_name
        end
      end

      let(:expected_stub_attrs) { stub_attrs.tap { |a| a['http.method'] = 'GET' } }

      let(:expected_internal_attrs) do
        stub_attrs.tap do |attrs|
          attrs['net.peer.name'] = 'lambda.us-east-1.amazonaws.com'
          attrs['net.peer.port'] = '443'
        end
      end

      it 'creates spans with all the supplied parameters' do
        skip unless TestHelper.telemetry_plugin?(service_name)
        client.list_functions

        _(client_span.name).must_equal('Lambda.ListFunctions')
        _(stub_span.name).must_equal('Handler.StubResponses')
        _(client_span.kind).must_equal(:client)
        _(stub_span.kind).must_equal(:internal)
        TestHelper.match_span_attrs(expected_client_attrs, client_span, self)
        TestHelper.match_span_attrs(expected_stub_attrs, stub_span, self)
        _(stub_span.parent_span_id).must_equal(client_span.span_id)
      end

      it 'creates spans with all the non-stubbed parameters' do
        skip unless TestHelper.telemetry_plugin?(service_name)
        stub_request(:get, 'https://lambda.us-east-1.amazonaws.com/2015-03-31/functions/')

        client = Aws::Lambda::Client.new(
          telemetry_provider: otel_provider,
          credentials: Aws::Credentials.new('akid', 'secret'),
          region: 'us-east-1'
        )
        client.list_functions

        _(client_span.name).must_equal('Lambda.ListFunctions')
        _(internal_span.name).must_equal('Handler.NetHttp')
        _(client_span.kind).must_equal(:client)
        _(internal_span.kind).must_equal(:internal)
        _(client_span.attributes['aws.region']).must_equal('us-east-1')
        TestHelper.match_span_attrs(expected_internal_attrs, internal_span, self)
      end

      it 'should have correct span attributes when error' do
        skip unless TestHelper.telemetry_plugin?(service_name)
        stub_request(:get, 'foo').to_return(status: 400)

        begin
          client.list_functions
        rescue Aws::Lambda::Errors::BadRequest
          _(client_span.status.code).must_equal(2)
          _(client_span.events[0].name).must_equal('exception')
          _(internal_span.attributes['http.status_code']).must_equal('400')
        end
      end
    end

    describe 'SNS' do
      let(:service_name) { 'SNS' }
      let(:client) do
        Aws::SNS::Client.new(
          telemetry_provider: otel_provider,
          stub_responses: true
        )
      end
      let(:client_span) { spans.find { |s| s.name.include?('SNS.Publish') } }

      let(:expected_client_attrs) do
        client_attrs.tap do |attrs|
          attrs[otel_semantic::CODE_FUNCTION] = 'publish'
          attrs[otel_semantic::RPC_METHOD] = 'Publish'
          attrs[otel_semantic::RPC_SERVICE] = service_name
          attrs[otel_semantic::MESSAGING_DESTINATION_KIND] = 'topic'
          attrs[otel_semantic::MESSAGING_DESTINATION] = 'TopicName'
          attrs[otel_semantic::MESSAGING_SYSTEM] = 'aws.sns'
        end
      end

      let(:expected_stub_attrs) { stub_attrs.tap { |a| a['http.method'] = 'POST' } }

      it 'creates spans with appropriate messaging attributes' do
        skip unless TestHelper.telemetry_plugin?(service_name)

        client.publish(
          message: 'msg',
          topic_arn: 'arn:aws:sns:fake:123:TopicName'
        )

        _(client_span.name).must_equal('SNS.Publish.TopicName.Publish')
        _(client_span.kind).must_equal(:producer)
        _(stub_span.name).must_equal('Handler.StubResponses')
        _(stub_span.kind).must_equal(:internal)
        TestHelper.match_span_attrs(expected_client_attrs, client_span, self)
        TestHelper.match_span_attrs(expected_stub_attrs, stub_span, self)
        _(stub_span.parent_span_id).must_equal(client_span.span_id)
      end

      it 'creates a span that includes a phone number' do
        # skip if using aws-sdk version before phone_number supported (v2.3.18)
        skip if Gem::Version.new('2.3.18') > instrumentation_gem_version
        skip unless TestHelper.telemetry_plugin?(service_name)

        client.publish(message: 'msg', phone_number: '123456')

        _(client_span.name).must_equal('SNS.Publish.phone_number.Publish')
        _(client_span.attributes[otel_semantic::MESSAGING_DESTINATION])
          .must_equal('phone_number')
      end
    end

    describe 'SQS' do
      let(:service_name) { 'SQS' }
      let(:client) do
        Aws::SQS::Client.new(
          telemetry_provider: otel_provider,
          stub_responses: true
        )
      end
      let(:queue_url) { 'https://sqs.us-east-1.amazonaws.com/1/QueueName' }
      let(:expected_client_base_attrs) do
        client_attrs.tap do |attrs|
          attrs[otel_semantic::RPC_SERVICE] = service_name
          attrs[otel_semantic::MESSAGING_DESTINATION_KIND] = 'queue'
          attrs[otel_semantic::MESSAGING_DESTINATION] = 'QueueName'
          attrs[otel_semantic::MESSAGING_SYSTEM] = 'aws.sqs'
          attrs[otel_semantic::MESSAGING_URL] = queue_url
        end
      end

      let(:expected_stub_attrs) { stub_attrs.tap { |a| a['http.method'] = 'POST' } }

      describe '#SendMessage' do
        let(:client_span) { spans.find { |s| s.name.include?('SQS.SendMessage') } }
        let(:expected_client_attrs) do
          expected_client_base_attrs.tap do |attrs|
            attrs[otel_semantic::RPC_METHOD] = 'SendMessage'
          end
        end

        it 'creates spans with appropriate messaging attributes' do
          skip unless TestHelper.telemetry_plugin?(service_name)

          client.send_message(message_body: 'msg', queue_url: queue_url)

          _(client_span.name).must_equal('SQS.SendMessage.QueueName.Publish')
          _(client_span.kind).must_equal(:producer)
          _(stub_span.name).must_equal('Handler.StubResponses')
          _(stub_span.kind).must_equal(:internal)
          TestHelper.match_span_attrs(expected_client_attrs, client_span, self)
          TestHelper.match_span_attrs(expected_stub_attrs, stub_span, self)
          _(stub_span.parent_span_id).must_equal(client_span.span_id)
        end
      end

      describe '#SendMessageBatch' do
        let(:client_span) { spans.find { |s| s.name.include?('SQS.SendMessageBatch') } }
        let(:expected_client_attrs) do
          expected_client_base_attrs.tap do |attrs|
            attrs[otel_semantic::RPC_METHOD] = 'SendMessageBatch'
          end
        end

        it 'creates spans with appropriate messaging attributes' do
          skip unless TestHelper.telemetry_plugin?(service_name)

          client.send_message_batch(
            queue_url: queue_url,
            entries: [{ id: 'Message1', message_body: 'Body1' }]
          )

          _(client_span.name).must_equal('SQS.SendMessageBatch.QueueName.Publish')
          _(client_span.kind).must_equal(:producer)
          _(stub_span.name).must_equal('Handler.StubResponses')
          _(stub_span.kind).must_equal(:internal)
          TestHelper.match_span_attrs(expected_client_attrs, client_span, self)
          TestHelper.match_span_attrs(expected_stub_attrs, stub_span, self)
          _(stub_span.parent_span_id).must_equal(client_span.span_id)
        end
      end

      describe '#ReceiveMessage' do
        let(:client_span) { spans.find { |s| s.name.include?('SQS.ReceiveMessage') } }
        let(:expected_client_attrs) do
          expected_client_base_attrs.tap do |attrs|
            attrs[otel_semantic::RPC_METHOD] = 'ReceiveMessage'
            attrs[otel_semantic::MESSAGING_OPERATION] = 'receive'
          end
        end

        it 'creates spans with appropriate messaging attributes' do
          skip unless TestHelper.telemetry_plugin?(service_name)

          client.receive_message(queue_url: queue_url)

          _(client_span.name).must_equal('SQS.ReceiveMessage.QueueName.Receive')
          _(client_span.kind).must_equal(:consumer)
          _(stub_span.name).must_equal('Handler.StubResponses')
          _(stub_span.kind).must_equal(:internal)
          TestHelper.match_span_attrs(expected_client_attrs, client_span, self)
          TestHelper.match_span_attrs(expected_stub_attrs, stub_span, self)
          _(stub_span.parent_span_id).must_equal(client_span.span_id)
        end
      end

      describe '#GetQueueUrl' do
        let(:client_span) { spans.find { |s| s.name.include?('SQS.GetQueueUrl') } }

        it 'creates a span with appropriate messaging attributes' do
          skip unless TestHelper.telemetry_plugin?(service_name)

          client.get_queue_url(queue_name: 'queue-name')

          _(client_span.attributes[otel_semantic::MESSAGING_DESTINATION]).must_equal('unknown')
          _(client_span.attributes).wont_include(otel_semantic::MESSAGING_URL)
        end
      end
    end

    describe 'DynamoDB' do
      let(:client) do
        Aws::DynamoDB::Client.new(
          telemetry_provider: otel_provider,
          stub_responses: true
        )
      end
      let(:client_span) { TestHelper.find_span(spans, 'DynamoDB.ListTables') }
      let(:client_span) { spans.find { |s| s.name == 'DynamoDB.ListTables' } }

      it 'creates a span with dynamodb-specific attribute' do
        skip unless TestHelper.telemetry_plugin?('DynamoDB')

        client.list_tables

        _(client_span.attributes[otel_semantic::DB_SYSTEM])
          .must_equal('dynamodb')
      end
    end
  end
end
