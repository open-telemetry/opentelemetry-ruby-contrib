# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'open3'

module OpenTelemetry
  module Resource
    module Detector
      # OS contains detect class method for determining OS resource attributes
      module OS
        extend self

        RESOURCE = OpenTelemetry::SDK::Resources::Resource
        SEMCONV = OpenTelemetry::SemConv::Incubating::OS

        def detect
          resource_attributes =
            case target_os
            when /linux/ then read_linux_attrs
            when /darwin/ then read_macos_attrs
            when /mswin|msys|mingw|cygwin/ then read_windows_attrs
            end
          OpenTelemetry::SDK::Resources::Resource.create(resource_attributes)
        end

        private

        def target_os
          RbConfig::CONFIG['target_os']
        end

        def read_linux_attrs
          attrs = {
            SEMCONV::OS_TYPE => 'linux'
          }
          build_id = nil
          os_release = read_linux_os_release
          if os_release
            # eg. "Ubuntu"
            name = lookup_os_release(os_release, 'NAME')
            attrs[SEMCONV::OS_NAME] = name if name
            # eg. "26.04"
            ver_id = lookup_os_release(os_release, 'VERSION_ID')
            attrs[SEMCONV::OS_VERSION] = ver_id if ver_id
            # eg. "Ubuntu 26.04 LTS"
            pretty = lookup_os_release(os_release, 'PRETTY_NAME')
            attrs[SEMCONV::OS_DESCRIPTION] = pretty if pretty
            # eg. "7.0.0-1008-aws",
            #     "5.15.146.1-microsoft-standard-WSL2+"
            build_id = lookup_os_release(os_release, 'BUILD_ID')
          end
          if build_id
            attrs[SEMCONV::OS_BUILD_ID] = build_id
          elsif File.readable?('/proc/sys/kernel/osrelease')
            attrs[SEMCONV::OS_BUILD_ID] = File.read('/proc/sys/kernel/osrelease').strip
          end
          attrs
        end

        def read_linux_os_release
          if File.readable?('/etc/os-release')
            File.read('/etc/os-release')
          elsif File.readable?('/usr/lib/os-release')
            File.read('/usr/lib/os-release')
          end
        end

        def lookup_os_release(os_release, key)
          os_release[/^#{key}="?(.*?)"?$/, 1]
        end

        def read_macos_attrs
          {
            SEMCONV::OS_TYPE => 'darwin',
            SEMCONV::OS_NAME => 'macOS'
          }
        end

        def read_windows_attrs
          {
            SEMCONV::OS_TYPE => 'windows',
            SEMCONV::OS_NAME => 'Windows',
            # eg. "10.0.26200"
            SEMCONV::OS_VERSION => Etc.uname[:release],
            # eg. "Microsoft Windows [Version 10.0.26200.8037]"
            SEMCONV::OS_DESCRIPTION => read_windows_ver.strip
          }
        end

        def read_windows_ver
          stdout, _stderr, _status = Open3.capture3('ver')
          stdout
        end
      end
    end
  end
end
