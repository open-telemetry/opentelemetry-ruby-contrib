# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Resource
    module Detector
      # Render contains detect class method for determining Render environment resource attributes
      module Render
        extend self

        RESOURCE = OpenTelemetry::SemanticConventions::Resource

        def detect
          resource_attributes = {}
          if ENV.fetch('RENDER', false) == 'true'
            resource_attributes[RESOURCE::CLOUD_PROVIDER] = 'render'
            resource_attributes['render.is_pull_request'] = ENV.fetch('IS_PULL_REQUEST', 'false')
            resource_attributes['render.git.branch'] = ENV.fetch('RENDER_GIT_BRANCH', nil)
            resource_attributes['render.git.repo_slug'] = ENV.fetch('RENDER_GIT_REPO_SLUG', nil)
            resource_attributes[RESOURCE::SERVICE_INSTANCE_ID] = ENV.fetch('RENDER_INSTANCE_ID', nil)
            resource_attributes[RESOURCE::SERVICE_NAME] = ENV.fetch('RENDER_SERVICE_NAME', 'unknown_service')
            resource_attributes[RESOURCE::SERVICE_VERSION] = ENV.fetch('RENDER_GIT_COMMIT', nil)

            resource_attributes.delete_if { |_key, value| value.nil? || value.empty? }
          else
            OpenTelemetry.logger.warn('Render resource detector did not detect Render environment')
          end

          OpenTelemetry::SDK::Resources::Resource.create(resource_attributes)
        end
      end
    end
  end
end
