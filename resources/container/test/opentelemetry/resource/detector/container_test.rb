# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detector::Container do
  let(:detector) { OpenTelemetry::Resource::Detector::Container }

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
      let(:container_id_v1) { '35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421' }
      let(:container_id_v2) { '35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6422' }
      let(:cgroup_v1_path) { '/proc/self/cgroup' }
      let(:cgroup_v2_path) { '/proc/self/mountinfo' }

      # rubocop:disable Layout/LineLength
      let(:cgroup_v1) do
        [
          '14:name=systemd:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '13:rdma:/',
          '12:pids:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '11:hugetlb:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '10:net_prio:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '9:perf_event:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '8:net_cls:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '7:freezer:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '6:devices:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '5:memory:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '4:blkio:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '3:cpuacct:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '2:cpu:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421',
          '1:cpuset:/docker/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6421'
        ]
      end

      let(:cgroup_v2) do
        [
          '945 859 0:229 / / rw,relatime master:267 - overlay overlay rw,lowerdir=/var/lib/docker/overlay2/l/3QOOYAPADIUJJO4Y73KN47Y242:/var/lib/docker/overlay2/l/HPE5OQGRE2YQRGVSQRWUXA4RTU:/var/lib/docker/overlay2/l/BVD3Y2X4YSPTAJVRCRLWKDFWWD:/var/lib/docker/overlay2/l/XL5N554MN7ZAVX32NDWAZXNTR3:/var/lib/docker/overlay2/l/NLSD37CU5H67XFIU7YI3KZAKBJ:/var/lib/docker/overlay2/l/ZL2CW7PWHHQB5E5TTEGFACJ3NT:/var/lib/docker/overlay2/l/KMGUCNAWVRNRTDJC5LLVYEWYR2:/var/lib/docker/overlay2/l/NRJZZABF55K4XT422COYZ4LSUH:/var/lib/docker/overlay2/l/HORYSY7WXPEIGRSRVMC6D5TEJV:/var/lib/docker/overlay2/l/HQEC3GPJJ2M3UASHWSGUOZ6ZZ7:/var/lib/docker/overlay2/l/P752BFBFEI6QIO23BXLTB6YZH7,upperdir=/var/lib/docker/overlay2/61bd889143e5c67cb22aa79240757562a2bf735ca84d33c712b59b82406a2fbf/diff,workdir=/var/lib/docker/overlay2/61bd889143e5c67cb22aa79240757562a2bf735ca84d33c712b59b82406a2fbf/work',
          '794 793 0:198 / /proc rw,nosuid,nodev,noexec,relatime - proc proc rw',
          '795 793 0:199 / /dev rw,nosuid - tmpfs tmpfs rw,size=65536k,mode=755',
          '796 795 0:200 / /dev/pts rw,nosuid,noexec,relatime - devpts devpts rw,gid=5,mode=620,ptmxmode=666',
          '797 793 0:201 / /sys ro,nosuid,nodev,noexec,relatime - sysfs sysfs ro',
          '798 797 0:33 / /sys/fs/cgroup ro,nosuid,nodev,noexec,relatime - cgroup2 cgroup rw',
          '799 795 0:197 / /dev/mqueue rw,nosuid,nodev,noexec,relatime - mqueue mqueue rw',
          '800 795 0:202 / /dev/shm rw,nosuid,nodev,noexec,relatime - tmpfs shm rw,size=65536k',
          '802 793 254:1 /docker/volumes/opentelemetry-ruby-contrib_bundle/_data /bundle rw,relatime master:29 - ext4 /dev/vda1 rw',
          '804 793 254:1 /docker/containers/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6422/resolv.conf /etc/resolv.conf rw,relatime - ext4 /dev/vda1 rw',
          '805 793 254:1 /docker/containers/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6422/hostname /etc/hostname rw,relatime - ext4 /dev/vda1 rw',
          '806 793 254:1 /docker/containers/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6422/hosts /etc/hosts rw,relatime - ext4 /dev/vda1 rw',
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

      let(:cgroup_v2_podman) do
        [
          '961 812 0:58 / / ro,relatime - overlay overlay rw,lowerdir=/home/dracula/.local/share/containers/storage/overlay/l/4NB35A5Z4YGWDHXYEUZU4FN6BU,upperdir=/home/dracula/.local/share/containers/storage/overlay/a73044caca1b918335d1db6f0052d21d35045136f3aa86976dbad1ec96e2fdde/diff,workdir=/home/dracula/.local/share/containers/storage/overlay/a73044caca1b918335d1db6f0052d21d35045136f3aa86976dbad1ec96e2fdde/work,userxattr',
          '962 961 0:63 / /sys ro,nosuid,nodev,noexec,relatime - sysfs sysfs rw',
          '963 961 0:64 / /run rw,nosuid,nodev,relatime - tmpfs tmpfs rw,uid=2024,gid=2024,inode64',
          '973 961 0:65 / /tmp rw,nosuid,nodev,relatime - tmpfs tmpfs rw,uid=2024,gid=2024,inode64',
          '974 961 0:66 / /proc rw,nosuid,nodev,noexec,relatime - proc proc rw',
          '975 961 0:67 / /dev rw,nosuid - tmpfs tmpfs rw,size=65536k,mode=755,uid=2024,gid=2024,inode64',
          '976 961 0:68 / /var/tmp rw,nosuid,nodev,relatime - tmpfs tmpfs rw,uid=2024,gid=2024,inode64',
          '977 975 0:62 / /dev/mqueue rw,nosuid,nodev,noexec,relatime - mqueue mqueue rw',
          '978 975 0:69 / /dev/pts rw,nosuid,noexec,relatime - devpts devpts rw,gid=427684,mode=620,ptmxmode=666',
          '979 975 0:57 / /dev/shm rw,nosuid,nodev,noexec,relatime - tmpfs shm rw,size=64000k,uid=2024,gid=2024,inode64',
          '980 963 0:56 /containers/overlay-containers/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6422/userdata/.containerenv /run/.containerenv ro,nosuid,nodev,noexec,relatime - tmpfs tmpfs rw,size=783888k,nr_inodes=195972,mode=700,uid=2024,gid=2024,inode64',
          '981 961 0:56 /containers/overlay-containers/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6422/userdata/resolv.conf /etc/resolv.conf ro,nosuid,nodev,noexec,relatime - tmpfs tmpfs rw,size=783888k,nr_inodes=195972,mode=700,uid=2024,gid=2024,inode64',
          '982 961 0:56 /containers/overlay-containers/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6422/userdata/hosts /etc/hosts ro,nosuid,nodev,noexec,relatime - tmpfs tmpfs rw,size=783888k,nr_inodes=195972,mode=700,uid=2024,gid=2024,inode64',
          '983 961 0:56 /containers/overlay-containers/35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6422/userdata/hostname /etc/hostname ro,nosuid,nodev,noexec,relatime - tmpfs tmpfs rw,size=783888k,nr_inodes=195972,mode=700,uid=2024,gid=2024,inode64',
          '984 962 0:70 / /sys/fs/cgroup rw,nosuid,nodev,noexec,relatime - tmpfs cgroup rw,size=1024k,uid=2024,gid=2024,inode64',
          '985 984 0:44 / /sys/fs/cgroup/misc ro,nosuid,nodev,noexec,relatime - cgroup cgroup rw,misc',
          '986 984 0:43 / /sys/fs/cgroup/freezer ro,nosuid,nodev,noexec,relatime - cgroup cgroup rw,freezer'
        ]
      end
      # rubocop:enable Layout/LineLength

      let(:expected_resource_attributes_v1) do
        {
          'container.id' => container_id_v1
        }
      end

      let(:expected_resource_attributes_v2) do
        {
          'container.id' => container_id_v2
        }
      end

      it 'returns a resource with container id for cgroup v1' do
        File.stub :readable?, proc { |arg| arg == cgroup_v1_path } do
          File.stub(:readlines, cgroup_v1) do
            _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
            _(detected_resource_attributes).must_equal(expected_resource_attributes_v1)
          end
        end
      end

      it 'returns a resource with container id for cgroup v2 using docker' do
        File.stub :readable?, proc { |arg| arg == cgroup_v2_path } do
          File.stub(:readlines, cgroup_v2) do
            _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
            _(detected_resource_attributes).must_equal(expected_resource_attributes_v2)
          end
        end
      end

      it 'returns a resource with container id for cgroup v2 using podman' do
        File.stub :readable?, proc { |arg| arg == cgroup_v2_path } do
          File.stub(:readlines, cgroup_v2_podman) do
            _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
            _(detected_resource_attributes).must_equal(expected_resource_attributes_v2)
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
