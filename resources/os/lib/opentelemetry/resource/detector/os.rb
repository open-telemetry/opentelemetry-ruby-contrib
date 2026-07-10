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
          #resource_attributes[OpenTelemetry::SemConv::Incubating::OS::OS_DESCRIPTION] = get_os_description
          #resource_attributes[OpenTelemetry::SemConv::Incubating::OS::OS_NAME] = get_os_name
          #resource_attributes[OpenTelemetry::SemConv::Incubating::OS::OS_VERSION] = get_os_version
          #resource_attributes[OpenTelemetry::SemConv::Incubating::OS::OS_BUILD_ID] = get_os_build_id

          OpenTelemetry::SDK::Resources::Resource.create(resource_attributes)
        end

        private

        def get_os_type
          rbconfig = RbConfig::CONFIG['host_os']
          case rbconfig
          when /aix/                     then 'aix'
          when /darwin/                  then 'darwin'
          when /dragonfly/               then 'dragonflybsd'
          when /freebsd/                 then 'freebsd'
          when /hpux/                    then 'hpux'
          when /linux/                   then 'linux'
          when /netbsd/                  then 'netbsd'
          when /openbsd/                 then 'openbsd'
          when /solaris|sunos/           then 'solaris'
          when /mswin|msys|mingw|cygwin/ then 'windows'
          else
            rbconfig
          end
        end

        def get_os_description
        end

        def get_os_name
        end

        def get_os_version
        end

        def get_os_build_id
        end
      end
    end
  end
end
