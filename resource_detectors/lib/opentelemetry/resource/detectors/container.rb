# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

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

          resource_attributes[OpenTelemetry::SemanticConventions::Resource::CONTAINER_ID] = id unless id.nil?
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
      end
    end
  end
end
