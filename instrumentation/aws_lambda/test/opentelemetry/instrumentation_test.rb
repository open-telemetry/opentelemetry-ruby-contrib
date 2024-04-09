# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::AwsLambda do
  let(:instrumentation) { OpenTelemetry::Instrumentation::AwsLambda::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:event_v1) { EVENT_V1 }
  let(:event_v2) { EVENT_V2 }
  let(:event_record) { EVENT_RECORD }
  let(:sqs_record) { SQS_RECORD }
  let(:context) { CONTEXT }
  let(:last_span) { exporter.finished_spans.last }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::AwsLambda'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#compatible' do
    it 'returns true for supported gem versions' do
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
      instrumentation.instance_variable_set(:@installed, false)
    end
  end

  describe 'validate_wrapper' do
    it 'result should be span' do
      otel_wrapper = OpenTelemetry::Instrumentation::AwsLambda::Handler.new
      otel_wrapper.stub(:call_original_handler, {}) do
        otel_wrapper.call_wrapped(event: event_v1, context: context)
        _(last_span).must_be_kind_of(OpenTelemetry::SDK::Trace::SpanData)
      end
    end

    it 'validate_spans' do
      otel_wrapper = OpenTelemetry::Instrumentation::AwsLambda::Handler.new
      otel_wrapper.stub(:call_original_handler, {}) do
        otel_wrapper.call_wrapped(event: event_v1, context: context)

        _(last_span.name).must_equal 'sample.test'
        _(last_span.kind).must_equal :server
        _(last_span.status.code).must_equal 1
        _(last_span.hex_parent_span_id).must_equal '0000000000000000'

        _(last_span.attributes['aws.lambda.invoked_arn']).must_equal 'arn:aws:lambda:location:id:function_name:function_name'
        _(last_span.attributes['faas.invocation_id']).must_equal '41784178-4178-4178-4178-4178417855e'
        _(last_span.attributes['faas.trigger']).must_equal 'http'
        _(last_span.attributes['cloud.resource_id']).must_equal 'arn:aws:lambda:location:id:function_name:function_name'
        _(last_span.attributes['cloud.account.id']).must_equal 'id'
        _(last_span.attributes['http.method']).must_equal 'GET'
        _(last_span.attributes['http.route']).must_equal '/'
        _(last_span.attributes['http.target']).must_equal '/'
        _(last_span.attributes['http.user_agent']).must_equal 'curl/8.1.2'
        _(last_span.attributes['http.scheme']).must_equal 'http'
        _(last_span.attributes['net.host.name']).must_equal '127.0.0.1:3000'

        _(last_span.instrumentation_scope).must_be_kind_of OpenTelemetry::SDK::InstrumentationScope
        _(last_span.instrumentation_scope.name).must_equal 'OpenTelemetry::Instrumentation::AwsLambda'
        _(last_span.instrumentation_scope.version).must_equal '0.1.0'

        _(last_span.hex_span_id.size).must_equal 16
        _(last_span.hex_trace_id.size).must_equal 32
        _(last_span.trace_flags.sampled?).must_equal true
        _(last_span.tracestate.to_h.to_s).must_equal '{}'
      end
    end

    it 'validate_spans_with_parent_context' do
      event_v1['headers']['Traceparent'] = '00-48b05d64abe4690867685635f72bdbac-ff40ea9699e62af2-01'
      event_v1['headers']['Tracestate']  = 'otel=ff40ea9699e62af2-01'

      otel_wrapper = OpenTelemetry::Instrumentation::AwsLambda::Handler.new
      otel_wrapper.stub(:call_original_handler, {}) do
        otel_wrapper.call_wrapped(event: event_v1, context: context)

        _(last_span.name).must_equal 'sample.test'
        _(last_span.kind).must_equal :server

        _(last_span.hex_parent_span_id).must_equal 'ff40ea9699e62af2'
        _(last_span.hex_span_id.size).must_equal 16
        _(last_span.hex_trace_id.size).must_equal 32
        _(last_span.trace_flags.sampled?).must_equal true
        _(last_span.tracestate.to_h.to_s).must_equal '{"otel"=>"ff40ea9699e62af2-01"}'
      end
      event_v1['headers'].delete('traceparent')
      event_v1['headers'].delete('tracestate')
    end

    it 'validate_spans_with_v2_events' do
      otel_wrapper = OpenTelemetry::Instrumentation::AwsLambda::Handler.new
      otel_wrapper.stub(:call_original_handler, {}) do
        otel_wrapper.call_wrapped(event: event_v2, context: context)

        _(last_span.name).must_equal 'sample.test'
        _(last_span.kind).must_equal :server
        _(last_span.status.code).must_equal 1
        _(last_span.hex_parent_span_id).must_equal '0000000000000000'

        _(last_span.attributes['aws.lambda.invoked_arn']).must_equal 'arn:aws:lambda:location:id:function_name:function_name'
        _(last_span.attributes['faas.invocation_id']).must_equal '41784178-4178-4178-4178-4178417855e'
        _(last_span.attributes['faas.trigger']).must_equal 'http'
        _(last_span.attributes['cloud.account.id']).must_equal 'id'
        _(last_span.attributes['cloud.resource_id']).must_equal 'arn:aws:lambda:location:id:function_name:function_name'
        _(last_span.attributes['net.host.name']).must_equal 'id.execute-api.us-east-1.amazonaws.com'
        _(last_span.attributes['http.method']).must_equal 'POST'
        _(last_span.attributes['http.user_agent']).must_equal 'agent'
        _(last_span.attributes['http.route']).must_equal '/path/to/resource'
        _(last_span.attributes['http.target']).must_equal '/path/to/resource?parameter1=value1&parameter1=value2&parameter2=value'
      end
    end

    it 'validate_spans_with_records_from_non_gateway_request' do
      otel_wrapper = OpenTelemetry::Instrumentation::AwsLambda::Handler.new
      otel_wrapper.stub(:call_original_handler, {}) do
        otel_wrapper.call_wrapped(event: event_record, context: context)

        _(last_span.name).must_equal 'sample.test'
        _(last_span.kind).must_equal :consumer
        _(last_span.status.code).must_equal 1
        _(last_span.hex_parent_span_id).must_equal '0000000000000000'

        _(last_span.attributes['aws.lambda.invoked_arn']).must_equal 'arn:aws:lambda:location:id:function_name:function_name'
        _(last_span.attributes['faas.invocation_id']).must_equal '41784178-4178-4178-4178-4178417855e'
        _(last_span.attributes['cloud.resource_id']).must_equal 'arn:aws:lambda:location:id:function_name:function_name'
        _(last_span.attributes['cloud.account.id']).must_equal 'id'

        assert_nil(last_span.attributes['faas.trigger'])
        assert_nil(last_span.attributes['http.method'])
        assert_nil(last_span.attributes['http.user_agent'])
        assert_nil(last_span.attributes['http.route'])
        assert_nil(last_span.attributes['http.target'])
        assert_nil(last_span.attributes['net.host.name'])
      end
    end

    it 'validate_spans_with_records_from_sqs' do
      otel_wrapper = OpenTelemetry::Instrumentation::AwsLambda::Handler.new
      otel_wrapper.stub(:call_original_handler, {}) do
        otel_wrapper.call_wrapped(event: sqs_record, context: context)

        _(last_span.name).must_equal 'sample.test'
        _(last_span.kind).must_equal :consumer
        _(last_span.status.code).must_equal 1
        _(last_span.hex_parent_span_id).must_equal '0000000000000000'

        _(last_span.attributes['aws.lambda.invoked_arn']).must_equal 'arn:aws:lambda:location:id:function_name:function_name'
        _(last_span.attributes['faas.invocation_id']).must_equal '41784178-4178-4178-4178-4178417855e'
        _(last_span.attributes['cloud.resource_id']).must_equal 'arn:aws:lambda:location:id:function_name:function_name'
        _(last_span.attributes['cloud.account.id']).must_equal 'id'
        _(last_span.attributes['faas.trigger']).must_equal 'pubsub'
        _(last_span.attributes['messaging.operation']).must_equal 'process'
        _(last_span.attributes['messaging.system']).must_equal 'AmazonSQS'

        assert_nil(last_span.attributes['http.method'])
        assert_nil(last_span.attributes['http.user_agent'])
        assert_nil(last_span.attributes['http.route'])
        assert_nil(last_span.attributes['http.target'])
        assert_nil(last_span.attributes['net.host.name'])
      end
    end
  end

  describe 'validate_error_handling' do
    it 'handle error if original handler cause issue' do
      otel_wrapper = OpenTelemetry::Instrumentation::AwsLambda::Handler.new
      otel_wrapper.stub(:call_original_handler, ->(**_args) { raise StandardError, 'Simulated Error' }) do
        otel_wrapper.call_wrapped(event: event_v1, context: context)
      rescue StandardError
        _(last_span.name).must_equal 'sample.test'
        _(last_span.kind).must_equal :server

        _(last_span.status.code).must_equal 2
        _(last_span.status.description).must_equal 'Simulated Error'
        _(last_span.hex_parent_span_id).must_equal '0000000000000000'

        _(last_span.events[0].name).must_equal 'exception'
        _(last_span.events[0].attributes['exception.type']).must_equal 'StandardError'
        _(last_span.events[0].attributes['exception.message']).must_equal 'Simulated Error'

        _(last_span.hex_span_id.size).must_equal 16
        _(last_span.hex_trace_id.size).must_equal 32
        _(last_span.trace_flags.sampled?).must_equal true
        _(last_span.tracestate.to_h.to_s).must_equal '{}'
      end
    end

    it 'if wrapped handler cause otel-related issue, wont break the entire lambda call' do
      otel_wrapper = OpenTelemetry::Instrumentation::AwsLambda::Handler.new
      otel_wrapper.stub(:call_wrapped, { 'test' => 'ok' }) do
        otel_wrapper.stub(:call_original_handler, {}) do
          OpenTelemetry::Context.stub(:with_current, lambda { |_context|
            tracer.start_span('test_span', attributes: {}, kind: :server)
            raise StandardError, 'OTEL Error'
          }) do
            response = otel_wrapper.call_wrapped(event: event_v1, context: context)
            _(response['test']).must_equal 'ok'
          end
        end
      end
    end
  end
end
