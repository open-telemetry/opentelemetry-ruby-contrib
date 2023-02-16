# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'docker'

module OpenTelemetry
  module Resource
    module Detectors
      # Container contains detect class method for determining container resource attributes
      module Container
        extend self

        UUID_PATTERN = '[0-9a-f]{8}[-_]?[0-9a-f]{4}[-_]?[0-9a-f]{4}[-_]?[0-9a-f]{4}[-_]?[0-9a-f]{12}'
        CONTAINER_PATTERN = '[0-9a-f]{64}'
        CONTAINER_REGEX = /(?<container>#{UUID_PATTERN}|#{CONTAINER_PATTERN})(?:.scope)?$/.freeze
        CGROUP_V1_PATH = '/proc/self/cgroup'
        CGROUP_V2_PATH = '/proc/self/mountinfo'

        def detect
          id = container_id
          resource_attributes = {}

          unless id.nil?
            resource_attributes[OpenTelemetry::SemanticConventions::Resource::CONTAINER_ID] = id

            case container_runtime
            when 'docker'
              resource_attributes = add_docker_resource_attributes(resource_attributes, id)
            else
              puts 'Unsupported Container Runtime'
            end
          end
          resource_attributes.delete_if { |_key, value| value.nil? || value.empty? }
          OpenTelemetry::SDK::Resources::Resource.create(resource_attributes)
        end

        private

        def container_id
          [CGROUP_V2_PATH, CGROUP_V1_PATH].each do |cgroup|
            next unless File.readable?(cgroup)

            File.readlines(cgroup, chomp: true).each do |line|
              next unless line.include?(Socket.gethostname)

              parts = line.split('/')
              parts.shift

              parts.each do |part|
                return part if part.match?(CONTAINER_REGEX)
              end
            end
          end
          nil
        end

        def add_docker_resource_attributes(resource_attributes, id)
          current_container = docker_containers.select { |c| c.id.eql? id }.first
          image, tag = docker_container_image(current_container, docker_images)

          resource_attributes[OpenTelemetry::SemanticConventions::Resource::CONTAINER_NAME] = docker_container_name(current_container)
          resource_attributes[OpenTelemetry::SemanticConventions::Resource::CONTAINER_RUNTIME] = 'docker'
          resource_attributes[OpenTelemetry::SemanticConventions::Resource::CONTAINER_IMAGE_NAME] = image
          resource_attributes[OpenTelemetry::SemanticConventions::Resource::CONTAINER_IMAGE_TAG] = tag
          resource_attributes
        end

        def docker_containers
          Docker::Container.all
        rescue Errno::EACCES, Errno::ENOENT
          nil
        end

        def docker_images
          Docker::Image.all
        rescue Errno::EACCES, Errno::ENOENT
          nil
        end

        def docker_container_name(current_container)
          current_container.info['Names'].first.to_s
        end

        def container_runtime
          'docker' unless Docker.version.nil?
        rescue Errno::EACCES, Errno::ENOENT, Excon::Error::Socket
          puts 'Could not determine container runtime'
          nil
        end

        def docker_container_image(current_container, all_images)
          image_id = current_container.info['ImageID']
          image = all_images.select { |i| i.id.eql? image_id }.first
          image_name, image_tag = image.info['RepoTags'].first.split(':')
          [image_name.to_s, image_tag.to_s]
        end
      end
    end
  end
end
