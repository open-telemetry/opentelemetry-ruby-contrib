# frozen_string_literal: true

require 'opentelemetry'
require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Shoryuken gem
    module Shoryuken
    end
  end
end

require_relative './shoryuken/instrumentation'
require 'opentelemetry/common'
