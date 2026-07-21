# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'open3'
begin
  # (Windows only)
  require 'win32/registry'
rescue LoadError
end

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
          attrs = {
            SEMCONV::OS_TYPE => 'darwin'
          }
          plist = read_macos_ver_plist
          if plist
            ver = lookup_plist(plist, 'ProductVersion')
            attrs[SEMCONV::OS_VERSION] = ver if ver

            buildver = lookup_plist(plist, 'ProductBuildVersion')
            attrs[SEMCONV::OS_BUILD_ID] = buildver if buildver

            name = lookup_plist(plist, 'ProductName')
            attrs[SEMCONV::OS_NAME] = name if name

            attrs[SEMCONV::OS_DESCRIPTION] = "#{name} #{ver} (#{buildver})" if name && ver && buildver
          end
          attrs
        end

        def read_macos_ver_plist
          if File.readable?('/System/Library/CoreServices/SystemVersion.plist')
            File.read('/System/Library/CoreServices/SystemVersion.plist')
          elsif File.readable?('/System/Library/CoreServices/ServerVersion.plist')
            File.read('/System/Library/CoreServices/ServerVersion.plist')
          end
        end

        def lookup_plist(plist, key)
          plist[%r{<key>#{key}</key>\s*<string>(.*?)</string>}m, 1]
        end

        def read_windows_attrs
          attrs = {
            SEMCONV::OS_TYPE => 'windows',
            SEMCONV::OS_NAME => 'Windows'
          }
          build, version = read_windows_registry
          if build
            # eg. "10.0.26200.8037"
            attrs[SEMCONV::OS_VERSION] = version
            # eg. "Microsoft Windows [Version 10.0.26200.8037]"
            attrs[SEMCONV::OS_DESCRIPTION] = "Microsoft Windows [Version #{version}]"
            # eg. "26200"
            attrs[SEMCONV::OS_BUILD_ID] = build
          end
          attrs
        end

        def read_windows_registry
          reg = Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion')
          major = reg['CurrentMajorVersionNumber']
          minor = reg['CurrentMinorVersionNumber']
          build = reg['CurrentBuildNumber']
          ubr = reg['UBR']
          [build, "#{major}.#{minor}.#{build}.#{ubr}"]
        rescue StandardError
          nil
        end
      end
    end
  end
end
