# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Net
      module LDAP
        module Patches
          # Module to prepend to Net::LDAP for instrumentation
          module Instrumentation
            def initialize(args = {})
              super

              @instrumentation_service = args[:instrumentation_service] || OpenTelemetry::Instrumentation::Net::LDAP::InstrumentationService.new({
                                                                                                                                                   host: @host,
                                                                                                                                                   port: @port,
                                                                                                                                                   hosts: @hosts,
                                                                                                                                                   auth: @auth,
                                                                                                                                                   base: @base,
                                                                                                                                                   encryption: @encryption
                                                                                                                                                 })
            end
          end
        end
      end
    end
  end
end
