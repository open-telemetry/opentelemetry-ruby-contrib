# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# Fake messages and services for tests
require 'google/protobuf'
require 'twirp'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "test.GreetRequest" do
    optional :name, :string, 1
  end
  add_message "test.GreetReply" do
    optional :message, :string, 1
  end
end

module Test
  GreetRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup('test.GreetRequest').msgclass
  GreetReply = Google::Protobuf::DescriptorPool.generated_pool.lookup('test.GreetReply').msgclass
end

# Twirp Service
module Test
  class Greeter < Twirp::Service
    package 'test'
    service 'Greeter'
    rpc :Greet, GreetRequest, GreetReply, ruby_method: :greet
  end

  class GreeterClient < Twirp::Client
    client_for Greeter
  end
end

# Example service handler
class GreeterHandler
  def greet(request, _env)
    Test::GreetReply.new(message: "Hello, #{request.name}!")
  end
end

# Handler that raises errors
class ErrorGreeterHandler
  def greet(_request, _env)
    raise StandardError, 'Test error'
  end
end

# Handler that returns Twirp errors
class TwirpErrorGreeterHandler
  def greet(_request, _env)
    Twirp::Error.invalid_argument('Invalid name')
  end
end
