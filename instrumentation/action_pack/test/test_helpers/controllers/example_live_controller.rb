# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

class ExampleLiveController < ActionController::Base
  include ActionController::Live

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    10.times do
      response.stream.write "hello world\n"
      sleep 0.1
    end
  ensure
    response.stream.close
  end
end
