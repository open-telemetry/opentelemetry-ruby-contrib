# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::OS do
  let(:detector) { OpenTelemetry::Resource::Detector::OS }

  RESOURCE = OpenTelemetry::SemanticConventions::Resource
  DATA_DIR_OS_RESOURCE = File.read(File.join(__dir__, 'data/os-resource-sample.txt'))
  DATA_DIR_SYSVER_PLIST = File.read(File.join(__dir__, 'data/SystemVersion-sample.plist'))

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }

    describe 'on linux' do
      before do
        allow(detector).to receive(:target_os).and_return('linux')
      end

      it 'returns a resource with os.type = linux' do
        _(detected_resource_attributes['os.type']).must_equal('linux')
      end

      describe 'when /etc/os-release is available' do
        before do
          allow(File).to receive(:readable?).with('/etc/os-release').and_return(true)
          allow(File).to receive(:read).with('/etc/os-release').and_return(DATA_DIR_OS_RESOURCE)
        end

        it 'reads os.* from that file' do
          _(detected_resource_attributes['os.name']).must_equal('Ubuntu')
          _(detected_resource_attributes['os.version']).must_equal('22.04')
          _(detected_resource_attributes['os.description']).must_equal('Ubuntu 22.04.5 LTS')
          _(detected_resource_attributes['os.build_id']).must_equal('build1')
        end
      end

      describe 'when /usr/lib/os-release is available' do
        before do
          allow(File).to receive(:readable?).with('/etc/os-release').and_return(false)
          allow(File).to receive(:readable?).with('/usr/lib/os-release').and_return(true)
          allow(File).to receive(:read).with('/usr/lib/os-release').and_return(DATA_DIR_OS_RESOURCE)
        end

        it 'reads os.* from that file' do
          _(detected_resource_attributes['os.name']).must_equal('Ubuntu')
          _(detected_resource_attributes['os.version']).must_equal('22.04')
          _(detected_resource_attributes['os.description']).must_equal('Ubuntu 22.04.5 LTS')
          _(detected_resource_attributes['os.build_id']).must_equal('build1')
        end
      end

      describe 'when os-release does not have BUILD_ID' do
        before do
          allow(File).to receive(:readable?).with('/etc/os-release').and_return(true)
          allow(File).to receive(:read).with('/etc/os-release').and_return('')
        end

        it 'reads os.build_id from /proc if available' do
          allow(File).to receive(:readable?).with('/proc/sys/kernel/osrelease').and_return(true)
          allow(File).to receive(:read).with('/proc/sys/kernel/osrelease').and_return("7.0.0-1008-aws\n")
          _(detected_resource_attributes['os.build_id']).must_equal('7.0.0-1008-aws')
        end
      end

      describe 'when either os-release is unavailable' do
        before do
          allow(File).to receive(:readable?).with('/etc/os-release').and_return(false)
          allow(File).to receive(:readable?).with('/usr/lib/os-release').and_return(false)
        end

        it 'reads os.build_id from /proc if available' do
          allow(File).to receive(:readable?).with('/proc/sys/kernel/osrelease').and_return(true)
          allow(File).to receive(:read).with('/proc/sys/kernel/osrelease').and_return("7.0.0-1008-aws\n")
          _(detected_resource_attributes['os.build_id']).must_equal('7.0.0-1008-aws')
        end

        it 'does not set os.build_id if unavailable' do
          allow(File).to receive(:readable?).with('/proc/sys/kernel/osrelease').and_return(false)
          _(detected_resource_attributes.key?('os.build_id')).must_equal(false)
        end
      end
    end

    describe 'on macOS' do
      before do
        allow(detector).to receive(:target_os).and_return('darwin')
      end

      it 'returns a macOS resource' do
        _(detected_resource_attributes['os.type']).must_equal('darwin')
      end

      describe 'when SystemVersion.plist is available' do
        before do
          allow(File).to receive(:readable?).with('/System/Library/CoreServices/SystemVersion.plist').and_return(true)
          allow(File).to receive(:read).with('/System/Library/CoreServices/SystemVersion.plist').and_return(DATA_DIR_SYSVER_PLIST)
        end

        it 'reads os.* from that file' do
          _(detected_resource_attributes['os.name']).must_equal('macOS')
          _(detected_resource_attributes['os.version']).must_equal('14.8.4')
          _(detected_resource_attributes['os.description']).must_equal('macOS 14.8.4 (23J319)')
          _(detected_resource_attributes['os.build_id']).must_equal('23J319')
        end
      end

      describe 'when ServerVersion.plist is available' do
        before do
          allow(File).to receive(:readable?).with('/System/Library/CoreServices/SystemVersion.plist').and_return(false)
          allow(File).to receive(:readable?).with('/System/Library/CoreServices/ServerVersion.plist').and_return(true)
          allow(File).to receive(:read).with('/System/Library/CoreServices/ServerVersion.plist').and_return(DATA_DIR_SYSVER_PLIST)
        end

        it 'reads os.* from that file' do
          _(detected_resource_attributes['os.name']).must_equal('macOS')
          _(detected_resource_attributes['os.version']).must_equal('14.8.4')
          _(detected_resource_attributes['os.description']).must_equal('macOS 14.8.4 (23J319)')
          _(detected_resource_attributes['os.build_id']).must_equal('23J319')
        end
      end
    end

    describe 'on windows' do
      before do
        allow(detector).to receive(:target_os).and_return('mingw32')
      end

      it 'returns an os resource' do
        allow(detector).to receive(:read_windows_registry).and_return(
          [
            '26200',
            '10.0.26200.8037'
          ]
        )

        _(detected_resource_attributes['os.type']).must_equal('windows')
        _(detected_resource_attributes['os.name']).must_equal('Windows')
        _(detected_resource_attributes['os.version']).must_equal('10.0.26200.8037')
        _(detected_resource_attributes['os.description']).must_equal(
          'Microsoft Windows [Version 10.0.26200.8037]'
        )
        _(detected_resource_attributes['os.build_id']).must_equal('26200')
      end

      describe 'when failed to read registry' do
        before do
          allow(detector).to receive(:read_windows_registry).and_return(nil)
        end

        it 'returns an os resource with type and name' do
          _(detected_resource_attributes['os.type']).must_equal('windows')
          _(detected_resource_attributes['os.name']).must_equal('Windows')
        end
      end
    end
  end
end
