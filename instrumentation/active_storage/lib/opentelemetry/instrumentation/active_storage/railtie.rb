# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActiveStorage
      PREVIEW_SUBSCRIPTION = 'preview.active_storage'
      TRANSFORM_SUBSCRIPTION = 'transform.active_storage'
      ANALYZE_SUBSCRIPTION = 'analyze.active_storage'
      SERVICE_UPLOAD_SUBSCRIPTION = 'service_upload.active_storage'
      SERVICE_STERAMING_DOWNLOAD_SUBSCRIPTION = 'service_streaming_download.active_storage'
      SERVICE_DOWNLOAD_CHUNK = 'service_download_chunk.active_storage'
      SERVICE_DOWNLOAD_SUBSCRIPTION = 'service_download.active_storage'
      SERVICE_DELETE_SUBSCRIPTION = 'service_delete.active_storage'
      SERVICE_DELETE_PREFIXED_SUBSCRIPTION = 'service_delete_prefixed.active_storage'
      SERVICE_EXIST_SUBSCRIPTION = 'service_exist.active_storage'
      SERVICE_URL_SUBSCRIPTION = 'service_url.active_storage'
      SERVICE_UPDATE_METADATA_SUBSCRIPTION = 'service_update_metadata.active_storage'

      # This Railtie sets up subscriptions to relevant ActiveStorage notifications
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          ::OpenTelemetry::Instrumentation::ActiveSupport::Instrumentation.instance.install({})
          subscribe_to_preview
          subscribe_to_transform
          subscribe_to_analyze
          subscribe_to_service_upload
          subscribe_to_service_streaming_download
          subscribe_to_service_download_chunk
          subscribe_to_service_download
          subscribe_to_service_delete
          subscribe_to_service_delete_prefixed
          subscribe_to_service_exist
          subscribe_to_service_url
          subscribe_to_service_update_metadata
        end

        class << self
          def subscribe_to_preview
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              PREVIEW_SUBSCRIPTION
            )
          end

          def subscribe_to_transform
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              TRANSFORM_SUBSCRIPTION
            )
          end

          def subscribe_to_analyze
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              ANALYZE_SUBSCRIPTION
            )
          end

          def subscribe_to_service_upload
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              SERVICE_UPLOAD_SUBSCRIPTION
            )
          end

          def subscribe_to_service_streaming_download
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              SERVICE_STERAMING_DOWNLOAD_SUBSCRIPTION
            )
          end

          def subscribe_to_service_download_chunk
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              SERVICE_DOWNLOAD_CHUNK
            )
          end

          def subscribe_to_service_download
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              SERVICE_DOWNLOAD_SUBSCRIPTION
            )
          end

          def subscribe_to_service_delete
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              SERVICE_DELETE_SUBSCRIPTION
            )
          end

          def subscribe_to_service_delete_prefixed
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              SERVICE_DELETE_PREFIXED_SUBSCRIPTION
            )
          end

          def subscribe_to_service_exist
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              SERVICE_EXIST_SUBSCRIPTION
            )
          end

          def subscribe_to_service_url
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              SERVICE_URL_SUBSCRIPTION
            )
          end

          def subscribe_to_service_update_metadata
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActiveStorage::Instrumentation.instance.tracer,
              SERVICE_UPDATE_METADATA_SUBSCRIPTION
            )
          end

          def config
            ActiveStorage::Instrumentation.instance.config
          end
        end
      end
    end
  end
end
