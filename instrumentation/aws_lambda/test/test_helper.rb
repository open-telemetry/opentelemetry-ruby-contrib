# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/setup'
Bundler.require(:default, :development, :test)

require 'opentelemetry-instrumentation-aws_lambda'

require 'minitest/autorun'
require 'rspec/mocks/minitest_integration'

class MockLambdaContext
  attr_reader :aws_request_id, :invoked_function_arn, :function_name

  def initialize(aws_request_id:, invoked_function_arn:, function_name:)
    @aws_request_id = aws_request_id
    @invoked_function_arn = invoked_function_arn
    @function_name = function_name
  end
end

EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)

EVENT_V1 = {
  'body' => nil,
  'headers' => {
    'Accept' => '*/*',
    'Host' => '127.0.0.1:3000',
    'User-Agent' => 'curl/8.1.2',
    'X-Forwarded-Port' => 3000,
    'X-Forwarded-Proto' => 'http'
  },
  'httpMethod' => 'GET',
  'isBase64Encoded' => false,
  'multiValueHeaders' => {},
  'multiValueQueryStringParameters' => nil,
  'path' => '/',
  'pathParameters' => nil,
  'queryStringParameters' => nil,
  'requestContext' => {
    'accountId' => 123_456_789_012,
    'apiId' => 1_234_567_890,
    'domainName' => '127.0.0.1:3000',
    'extendedRequestId' => nil,
    'httpMethod' => 'GET',
    'identity' => {},
    'path' => '/',
    'protocol' => 'HTTP/1.1',
    'requestId' => 'db7f8e7a-4cc5-4f6d-987b-713d0d9052c3',
    'requestTime' => '08/Nov/2023:19:09:59 +0000',
    'requestTimeEpoch' => 1_699_470_599,
    'resourceId' => '123456',
    'resourcePath' => '/',
    'stage' => 'api'
  },
  'resource' => '/',
  'stageVariables' => nil,
  'version' => '1.0'
}.freeze

EVENT_V2 = {
  'version' => '2.0',
  'routeKey' => '$default',
  'rawPath' => '/path/to/resource',
  'rawQueryString' => 'parameter1=value1&parameter1=value2&parameter2=value',
  'cookies' => %w[cookie1 cookie2],
  'headers' => { 'header1' => 'value1', 'Header2' => 'value1,value2' },
  'queryStringParameters' => {},
  'requestContext' => {
    'accountId' => '123456789012',
    'apiId' => 'api-id',
    'authentication' => { 'clientCert' => {} },
    'authorizer' => {},
    'domainName' => 'id.execute-api.us-east-1.amazonaws.com',
    'domainPrefix' => 'id',
    'http' => {
      'method' => 'POST',
      'path' => '/path/to/resource',
      'protocol' => 'HTTP/1.1',
      'sourceIp' => '192.168.0.1/32',
      'userAgent' => 'agent'
    },
    'requestId' => 'id',
    'routeKey' => '$default',
    'stage' => '$default',
    'time' => '12/Mar/2020:19:03:58 +0000',
    'timeEpoch' => 1_583_348_638_390
  },
  'body' => 'eyJ0ZXN0IjoiYm9keSJ9',
  'pathParameters' => { 'parameter1' => 'value1' },
  'isBase64Encoded' => true,
  'stageVariables' => { 'stageVariable1' => 'value1', 'stageVariable2' => 'value2' }
}.freeze

EVENT_RECORD = {
  'Records' =>
    [
      { 'eventVersion' => '2.0',
        'eventSource' => 'aws:s3',
        'awsRegion' => 'us-east-1',
        'eventTime' => '1970-01-01T00:00:00.000Z',
        'eventName' => 'ObjectCreated:Put',
        'userIdentity' => { 'principalId' => 'EXAMPLE' },
        'requestParameters' => { 'sourceIPAddress' => '127.0.0.1' },
        'responseElements' => {
          'x-amz-request-id' => 'EXAMPLE123456789',
          'x-amz-id-2' => 'EXAMPLE123/5678abcdefghijklambdaisawesome/mnopqrstuvwxyzABCDEFGH'
        },
        's3' => {
          's3SchemaVersion' => '1.0',
          'configurationId' => 'testConfigRule',
          'bucket' => {
            'name' => 'mybucket',
            'ownerIdentity' => {
              'principalId' => 'EXAMPLE'
            },
            'arn' => 'arn:aws:s3:::mybucket'
          },
          'object' => {
            'key' => 'test/key',
            'size' => 1024,
            'eTag' => '0123456789abcdef0123456789abcdef',
            'sequencer' => '0A1B2C3D4E5F678901'
          }
        } }
    ]
}.freeze

SQS_RECORD = {
  'Records' =>
    [{ 'messageId' => '19dd0b57-b21e-4ac1-bd88-01bbb068cb78',
       'receiptHandle' => 'MessageReceiptHandle',
       'body' => 'Hello from SQS!',
       'attributes' =>
       { 'ApproximateReceiveCount' => '1',
         'SentTimestamp' => '1523232000000',
         'SenderId' => '123456789012',
         'ApproximateFirstReceiveTimestamp' => '1523232000001' },
       'messageAttributes' => {},
       'md5OfBody' => '7b270e59b47ff90a553787216d55d91d',
       'eventSource' => 'aws:sqs',
       'eventSourceARN' => 'arn:aws:sqs:us-east-1:123456789012:MyQueue',
       'awsRegion' => 'us-east-1' }]
}.freeze

CONTEXT = MockLambdaContext.new(aws_request_id: '41784178-4178-4178-4178-4178417855e',
                                invoked_function_arn: 'arn:aws:lambda:location:id:function_name:function_name',
                                function_name: 'funcion')

$LOAD_PATH.unshift("#{Dir.pwd}/example/")
ENV['ORIG_HANDLER'] = 'sample.test'
ENV['_HANDLER'] = 'sample.test'
OpenTelemetry::SDK.configure do |c|
  c.error_handler = ->(exception:, message:) { raise(exception || message) }
  c.logger = Logger.new($stderr, level: ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym)
  c.use 'OpenTelemetry::Instrumentation::AwsLambda'
  c.add_span_processor span_processor
end
