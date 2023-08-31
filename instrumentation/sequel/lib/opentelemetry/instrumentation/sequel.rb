# frozen_string_literal: true

require 'opentelemetry'
require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the Sequel gem
    module Sequel
    end
  end
end

require_relative 'sequel/instrumentation'
require_relative 'sequel/version'
