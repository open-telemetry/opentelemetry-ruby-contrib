# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detectors::Container do
  let(:detector) { OpenTelemetry::Resource::Detectors::Container }

  describe '.detect' do
    let(:detected_resource) { detector.detect }
    let(:detected_resource_attributes) { detected_resource.attribute_enumerator.to_h }
    let(:expected_resource_attributes) { {} }

    describe 'when NOT in a container environment' do
      it 'returns an empty resource' do
        _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
        _(detected_resource_attributes).must_equal(expected_resource_attributes)
      end
    end

    describe 'when in a container environment' do
      let(:container_id) { '35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427' }

      let(:cgroup_v1_path) { '/proc/self/cgroup' }
      let(:cgroup_v2_path) { '/proc/self/mountinfo' }
      let(:cgroup_v1) do
        [
          '14:name=systemd:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '13:rdma:/',
          '12:pids:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '11:hugetlb:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '10:net_prio:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '9:perf_event:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '8:net_cls:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '7:freezer:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '6:devices:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '5:memory:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '4:blkio:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '3:cpuacct:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '2:cpu:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427',
          '1:cpuset:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427'
        ]
      end

      let(:cgroup_v2) do
        [
          '794 793 0:198 / /proc rw,nosuid,nodev,noexec,relatime - proc proc rw',
          '795 793 0:199 / /dev rw,nosuid - tmpfs tmpfs rw,size=65536k,mode=755',
          '796 795 0:200 / /dev/pts rw,nosuid,noexec,relatime - devpts devpts rw,gid=5,mode=620,ptmxmode=666',
          '797 793 0:201 / /sys ro,nosuid,nodev,noexec,relatime - sysfs sysfs ro',
          '798 797 0:33 / /sys/fs/cgroup ro,nosuid,nodev,noexec,relatime - cgroup2 cgroup rw',
          '799 795 0:197 / /dev/mqueue rw,nosuid,nodev,noexec,relatime - mqueue mqueue rw',
          '800 795 0:202 / /dev/shm rw,nosuid,nodev,noexec,relatime - tmpfs shm rw,size=65536k',
          '802 793 254:1 /docker/volumes/opentelemetry-ruby-contrib_bundle/_data /bundle rw,relatime master:29 - ext4 /dev/vda1 rw',
          '804 793 254:1 /docker/containers/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427/resolv.conf /etc/resolv.conf rw,relatime - ext4 /dev/vda1 rw',
          '805 793 254:1 /docker/containers/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427/hostname /etc/hostname rw,relatime - ext4 /dev/vda1 rw',
          '806 793 254:1 /docker/containers/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427/hosts /etc/hosts rw,relatime - ext4 /dev/vda1 rw',
          '809 793 0:23 /host-services/docker.proxy.sock /run/docker.sock ro,relatime - tmpfs tmpfs rw,size=803996k,mode=755',
          '573 795 0:200 /0 /dev/console rw,nosuid,noexec,relatime - devpts devpts rw,gid=5,mode=620,ptmxmode=666',
          '609 794 0:198 /bus /proc/bus ro,nosuid,nodev,noexec,relatime - proc proc rw',
          '610 794 0:198 /fs /proc/fs ro,nosuid,nodev,noexec,relatime - proc proc rw',
          '611 794 0:198 /irq /proc/irq ro,nosuid,nodev,noexec,relatime - proc proc rw',
          '612 794 0:198 /sys /proc/sys ro,nosuid,nodev,noexec,relatime - proc proc rw',
          '613 794 0:198 /sysrq-trigger /proc/sysrq-trigger ro,nosuid,nodev,noexec,relatime - proc proc rw',
          '614 794 0:199 /null /proc/kcore rw,nosuid - tmpfs tmpfs rw,size=65536k,mode=755',
          '615 794 0:199 /null /proc/keys rw,nosuid - tmpfs tmpfs rw,size=65536k,mode=755',
          '616 794 0:199 /null /proc/timer_list rw,nosuid - tmpfs tmpfs rw,size=65536k,mode=755',
          '617 797 0:204 / /sys/firmware ro,relatime - tmpfs tmpfs ro'
        ]
      end

      let(:expected_resource_attributes) do
        {
          'container.id' => container_id
        }
      end

      it 'returns a resource with container id for cgroup v1' do
        File.stub :readable?, proc { |arg| arg == cgroup_v1_path } do
          File.stub(:readlines, cgroup_v1) do
            _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
            _(detected_resource_attributes).must_equal(expected_resource_attributes)
          end
        end
      end

      it 'returns a resource with container id for cgroup v2' do
        File.stub :readable?, proc { |arg| arg == cgroup_v2_path } do
          File.stub(:readlines, cgroup_v2) do
            _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
            _(detected_resource_attributes).must_equal(expected_resource_attributes)
          end
        end
      end

      describe 'and a nil resource value is detected' do
        let(:container_id) { nil }

        it 'returns a resource without that attribute' do
          _(detected_resource_attributes.key?('container.id')).must_equal(false)
        end
      end

      describe 'and an empty string resource value is detected' do
        let(:container_id) { '' }

        it 'returns a resource without that attribute' do
          _(detected_resource_attributes.key?('container.id')).must_equal(false)
        end
      end
    end
  end
end
