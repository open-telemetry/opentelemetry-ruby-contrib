# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module LDAP
        # The Instrumentation class contains logic to detect and install the Net::LDAP
        # instrumentation
        class Instrumentation < OpenTelemetry::Instrumentation::Base
          compatible do
            gem_version = Gem::Version.new(::Net::LDAP::VERSION)
            Gem::Requirement.new('>= 0.17.1').satisfied_by?(gem_version)
          end

          install do |_config|
            require_dependencies
            patch
          end

          present do
            defined?(::Net::LDAP)
          end

          option :peer_service, default: nil, validate: :string

          private

          def require_dependencies
            require_relative 'instrumentation_service'
            require_relative 'patches/instrumentation'
          end

          def patch
            ::Net::LDAP.prepend(Patches::Instrumentation)
          end
        end
      end
    end
  end
end
