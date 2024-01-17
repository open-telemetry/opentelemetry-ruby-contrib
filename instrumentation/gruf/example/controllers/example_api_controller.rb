# frozen_string_literal: true

require_relative '../base'

class ExampleApiController < Gruf::Controllers::Base
  bind Proto::Example::ExampleAPI::Service

  def example
    Proto::Example::ExampleResponse.new(response_name: 'Done')
  end
end
