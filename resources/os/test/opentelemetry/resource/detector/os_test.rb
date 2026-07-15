# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::OS do
  let(:detector) { OpenTelemetry::Resource::Detector::OS }

  RESOURCE = OpenTelemetry::SemanticConventions::Resource

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }

    describe 'on linux' do
      before do
        allow(detector).to receive(:target_os).and_return("linux")
      end

      it 'returns a resource with os.type = linux' do
        _(detected_resource_attributes['os.type']).must_equal("linux")
      end

      describe 'when /etc/os-release is available' do
        before do
          allow(File).to receive(:readable?).with("/etc/os-release").and_return(true)
          allow(File).to receive(:read).with("/etc/os-release").and_return(<<~EOD)
            PRETTY_NAME="Ubuntu 22.04.5 LTS"
            NAME="Ubuntu"
            VERSION_ID="22.04"
            VERSION="22.04.5 LTS (Jammy Jellyfish)"
            VERSION_CODENAME=jammy
            ID=ubuntu
            ID_LIKE=debian
            HOME_URL="https://www.ubuntu.com/"
            SUPPORT_URL="https://help.ubuntu.com/"
            BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
            PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
            UBUNTU_CODENAME=jammy
            BUILD_ID=build1
          EOD
        end

        it 'reads os.name from NAME' do
          _(detected_resource_attributes['os.name']).must_equal("Ubuntu")
        end

        it 'reads os.version from VERSION_ID' do
          _(detected_resource_attributes['os.version']).must_equal("22.04")
        end

        it 'reads os.description from PRETTY_NAME' do
          _(detected_resource_attributes['os.description']).must_equal("Ubuntu 22.04.5 LTS")
        end

        it 'reads os.build_id from BUILD_ID when available' do
          _(detected_resource_attributes['os.build_id']).must_equal("build1")
        end
      end

      describe 'when /usr/lib/os-release is available' do
        before do
          allow(File).to receive(:readable?).with("/etc/os-release").and_return(false)
          allow(File).to receive(:readable?).with("/usr/lib/os-release").and_return(true)
          allow(File).to receive(:read).with("/usr/lib/os-release").and_return(<<~EOD)
            PRETTY_NAME="Ubuntu 22.04.5 LTS"
            NAME="Ubuntu"
            VERSION_ID="22.04"
            VERSION="22.04.5 LTS (Jammy Jellyfish)"
            VERSION_CODENAME=jammy
            ID=ubuntu
            ID_LIKE=debian
            HOME_URL="https://www.ubuntu.com/"
            SUPPORT_URL="https://help.ubuntu.com/"
            BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
            PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
            UBUNTU_CODENAME=jammy
            BUILD_ID=build1
          EOD
        end

        it 'reads os.name from NAME' do
          _(detected_resource_attributes['os.name']).must_equal("Ubuntu")
        end

        it 'reads os.version from VERSION_ID' do
          _(detected_resource_attributes['os.version']).must_equal("22.04")
        end

        it 'reads os.description from PRETTY_NAME' do
          _(detected_resource_attributes['os.description']).must_equal("Ubuntu 22.04.5 LTS")
        end

        it 'reads os.build_id from BUILD_ID when available' do
          _(detected_resource_attributes['os.build_id']).must_equal("build1")
        end
      end

      describe 'when os-release does not have BUILD_ID' do
        before do
          allow(File).to receive(:readable?).with("/etc/os-release").and_return(true)
          allow(File).to receive(:read).with("/etc/os-release").and_return("")
        end

        it 'reads os.build_id from /proc if available' do
          allow(File).to receive(:readable?).with("/proc/sys/kernel/osrelease").and_return(true)
          allow(File).to receive(:read).with("/proc/sys/kernel/osrelease").and_return("7.0.0-1008-aws\n")
          _(detected_resource_attributes['os.build_id']).must_equal("7.0.0-1008-aws")
        end
      end

      describe 'when either os-release is unavailable' do
        before do
          allow(File).to receive(:readable?).with("/etc/os-release").and_return(false)
          allow(File).to receive(:readable?).with("/usr/lib/os-release").and_return(false)
        end

        it 'reads os.build_id from /proc if available' do
          allow(File).to receive(:readable?).with("/proc/sys/kernel/osrelease").and_return(true)
          allow(File).to receive(:read).with("/proc/sys/kernel/osrelease").and_return("7.0.0-1008-aws\n")
          _(detected_resource_attributes['os.build_id']).must_equal("7.0.0-1008-aws")
        end

        it 'does not set os.build_id if unavailable' do
          allow(File).to receive(:readable?).with("/proc/sys/kernel/osrelease").and_return(false)
          _(detected_resource_attributes.key?('os.build_id')).must_equal(false)
        end
      end
    end
    
    describe 'on macOS' do
      # TODO
    end
    
    describe 'on windows' do
      before do
        allow(detector).to receive(:target_os).and_return("mingw32")
        allow(Open3).to receive(:capture3).with("ver").and_return([
          "\nMicrosoft Windows [Version 10.0.26200.8037]\n",
          nil,
          nil,
        ])
      end

      it 'returns a resource with os.type = windows' do
        _(detected_resource_attributes['os.type']).must_equal("windows")
      end

      it 'returns a resource with os.name = Windows' do
        _(detected_resource_attributes['os.name']).must_equal("Windows")
      end

      it 'returns a resource with os.description (newlines deleted)' do
        _(detected_resource_attributes['os.description']).must_equal(
          "Microsoft Windows [Version 10.0.26200.8037]"
        )
      end
    end
  end
end
