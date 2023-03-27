# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Resource::Detectors::Container do
  before do
    WebMock.disable_net_connect!

    stub_request(:get, 'http://unix/version')
      .with(
        headers: {
          'Accept' => '*/*',
          'Content-Type' => 'text/plain',
          'Host' => '',
          'User-Agent' => 'Swipely/Docker-API 2.2.0'
        }
      )
      .to_return(status: 200, body: '', headers: {})

    stub_request(:get, 'http://unix/containers/json')
      .with(
        headers: {
          'Accept' => '*/*',
          'Content-Type' => 'text/plain',
          'Host' => '',
          'User-Agent' => 'Swipely/Docker-API 2.2.0'
        }
      )
      .to_return(status: 200, body: '', headers: {})

    stub_request(:get, 'http://unix/images/json')
      .with(
        headers: {
          'Accept' => '*/*',
          'Content-Type' => 'text/plain',
          'Host' => '',
          'User-Agent' => 'Swipely/Docker-API 2.2.0'
        }
      )
      .to_return(status: 200, body: '', headers: {})
  end

  after do
    WebMock.allow_net_connect!
  end

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

      # rubocop:disable Layout/LineLength
      let(:cgroup_v2) do
        [
          '793 717 0:189 / / rw,relatime master:202 - overlay overlay rw,lowerdir=/var/lib/docker/overlay2/l/EMWHDEA3KNHY7IR3PXONGCBMFD:/var/lib/docker/overlay2/l/HPE5OQGRE2YQRGVSQRWUXA4RTU:/var/lib/docker/overlay2/l/BVD3Y2X4YSPTAJVRCRLWKDFWWD:/var/lib/docker/overlay2/l/XL5N554MN7ZAVX32NDWAZXNTR3:/var/lib/docker/overlay2/l/NLSD37CU5H67XFIU7YI3KZAKBJ:/var/lib/docker/overlay2/l/ZL2CW7PWHHQB5E5TTEGFACJ3NT:/var/lib/docker/overlay2/l/KMGUCNAWVRNRTDJC5LLVYEWYR2:/var/lib/docker/overlay2/l/NRJZZABF55K4XT422COYZ4LSUH:/var/lib/docker/overlay2/l/HORYSY7WXPEIGRSRVMC6D5TEJV:/var/lib/docker/overlay2/l/HQEC3GPJJ2M3UASHWSGUOZ6ZZ7:/var/lib/docker/overlay2/l/P752BFBFEI6QIO23BXLTB6YZH7,upperdir=/var/lib/docker/overlay2/0c6c154e16db661ee70065ea1fb95dd61c626c574695ef9c2e3801427d8b8eb2/diff,workdir=/var/lib/docker/overlay2/0c6c154e16db661ee70065ea1fb95dd61c626c574695ef9c2e3801427d8b8eb2/work',
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
      # rubocop:enable Layout/LineLength

      let(:expected_resource_attributes) do
        {
          'container.id' => container_id
        }
      end

      let(:expected_resource_attributes_on_docker_container_runtime) do
        {
          'container.id' => container_id,
          'container.image.name' => 'opentelemetry/opentelemetry-ruby-contrib',
          'container.image.tag' => 'latest',
          'container.name' => '/opentelemetry-ruby-contrib-ex-instrumentation-sinatra-1',
          'container.runtime' => 'docker'
        }
      end

      describe 'and the docker socket is not readable' do
        it 'returns a resource with container id' do
          Socket.stub(:gethostname, container_id) do
            File.stub(:readable?, true) do
              File.stub(:readlines, cgroup_v2) do
                _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
                _(detected_resource_attributes).must_equal(expected_resource_attributes)
              end
            end
          end
        end
      end

      describe 'and the docker socket is readable' do
        let(:docker_containers_info) do
          {
            'Names' => [
              '/opentelemetry-ruby-contrib-ex-instrumentation-sinatra-1'
            ],
            'Image' => 'opentelemetry/opentelemetry-ruby-contrib',
            'ImageID' => 'sha256:a6cfa58bb573821dae0fcd19d65356e193fbd20eeb0cc4e04d1046b2bbef9df1',
            'id' => '35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427'
          }
        end

        let(:docker_images_info) do
          {
            'Containers' => -1,
            'Created' => 1_659_078_472,
            'Labels' => {
              'maintainer' => 'open-telemetry/opentelemetry-ruby-contrib'
            },
            'RepoTags' => [
              'opentelemetry/opentelemetry-ruby-contrib:latest'
            ]
          }
        end

        it 'returns a resource with container id and additional container resource attributes' do
          docker_containers = MiniTest::Mock.new
          docker_containers.expect(:id, '35d6ec5d6d56dec8fb31725b6c201ac20d775b71e8ec47786cb949621b3d6427')
          docker_containers.expect(:info, docker_containers_info)
          docker_containers.expect(:info, docker_containers_info)

          docker_images = MiniTest::Mock.new
          docker_images.expect(:id, 'sha256:a6cfa58bb573821dae0fcd19d65356e193fbd20eeb0cc4e04d1046b2bbef9df1')
          docker_images.expect(:info, docker_images_info)

          Socket.stub(:gethostname, container_id) do
            File.stub(:readable?, true) do
              File.stub(:readlines, cgroup_v2) do
                Docker.stub(:version, { 'Platform' => { 'Name' => 'Docker Desktop 4.17.0 (99724)' } }) do
                  Docker::Container.stub(:all, [docker_containers]) do
                    Docker::Image.stub(:all, [docker_images]) do
                      _(detected_resource).must_be_instance_of(OpenTelemetry::SDK::Resources::Resource)
                      _(detected_resource_attributes).must_equal(expected_resource_attributes_on_docker_container_runtime)
                    end
                  end
                end
              end
            end
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
