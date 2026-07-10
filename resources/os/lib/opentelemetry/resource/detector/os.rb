# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Resource
    module Detector
      # OS contains detect class method for determining OS resource attributes
      module OS
        extend self

        RESOURCE = OpenTelemetry::SDK::Resources::Resource

        def detect
          resource_attributes = {}

          resource_attributes[OpenTelemetry::SemConv::Incubating::OS::OS_TYPE] = get_os_type
          resource_attributes[OpenTelemetry::SemConv::Incubating::OS::OS_DESCRIPTION] = get_os_description
          resource_attributes[OpenTelemetry::SemConv::Incubating::OS::OS_NAME] = get_os_name
          resource_attributes[OpenTelemetry::SemConv::Incubating::OS::OS_VERSION] = get_os_version

          OpenTelemetry::SDK::Resources::Resource.create(resource_attributes)
        end

        private

        def get_os_type
        end

        def get_os_description
        end

        def get_os_name
        end

        def get_os_version
        end
      end
    end
  end
end
