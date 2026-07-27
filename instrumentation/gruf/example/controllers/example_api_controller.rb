# frozen_string_literal: true

require_relative '../base'
# Sample Gruf service used to demonstrate the OpenTelemetry instrumentation.
class ExampleApiController < Gruf::Controllers::Base
  bind Proto::Example::ExampleAPI::Service

  def example
    Proto::Example::ExampleResponse.new(response_name: 'Done')
  end
end
