# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'
require_relative './sample'

Bundler.require

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'
ENV['ORIG_HANDLER'] ||= 'sample.handler'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::AwsLambda'
end

class MockLambdaContext
  attr_reader :aws_request_id, :invoked_function_arn

  def initialize(aws_request_id:, invoked_function_arn:)
    @aws_request_id = aws_request_id
    @invoked_function_arn = invoked_function_arn
  end
end

def otel_wrapper(event:, context:)
  otel_wrapper = OpenTelemetry::Instrumentation::AwsLambda::Handler.new()
  otel_wrapper.call_wrapped(event: event, context: context)
end

# sample event obtained from sample test
event = {
   "body" => nil,
   "headers" => {
      "Accept" => "*/*",
      "Host" => "127.0.0.1:3000",
      "User-Agent" => "curl/8.1.2",
      "X-Forwarded-Port" => 3000,
      "X-Forwarded-Proto" => "http"
   },
   "httpMethod" => "GET",
   "isBase64Encoded" => false,
   "multiValueHeaders" => {},
   "multiValueQueryStringParameters" => nil,
   "path" => "/",
   "pathParameters" => nil,
   "queryStringParameters" => nil,
   "requestContext":{
      "accountId" => 123456789012,
      "apiId" => 1234567890,
      "domainName" => "127.0.0.1:3000",
      "extendedRequestId" => nil,
      "httpMethod" => "GET",
      "identity" => {},
      "path" => "/",
      "protocol" => "HTTP/1.1",
      "requestId" => "db7f8e7a-4cc5-4f6d-987b-713d0d9052c3",
      "requestTime" => "08/Nov/2023:19:09:59 +0000",
      "requestTimeEpoch" => 1699470599,
      "resourceId" => "123456",
      "resourcePath" => "/",
      "stage" => "api"
   },
   "resource" => "/",
   "stageVariables" => nil,
   "version" => "1.0"
}

context = MockLambdaContext.new(aws_request_id: "aws_request_id",invoked_function_arn: "invoked_function_arn")

otel_wrapper(event: event, context: context) # you should see Success before the trace
