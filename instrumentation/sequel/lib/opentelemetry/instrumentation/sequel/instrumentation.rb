# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'sequel/extensions/opentelemetry'

module OpenTelemetry
  module Instrumentation
    module Sequel
      # The Instrumentation class contains logic to detect and install the Sequel
      # instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        MINIMUM_VERSION = Gem::Version.new('5.29.0')

        install do |_|
          ::Sequel.extension(:opentelemetry)

          ::Sequel.synchronize { ::Sequel::DATABASES.dup }.each { |db| db.extension(:opentelemetry) }
        end

        present do
          defined?(::Sequel)
        end

        compatible do
          gem_version >= MINIMUM_VERSION
        end

        def gem_version
          Gem::Version.new(::Sequel.version)
        end
      end
    end
  end
end
