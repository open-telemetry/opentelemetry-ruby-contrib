# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry-instrumentation-active_support'

describe OpenTelemetry::Instrumentation::ActiveStorage do
  let(:exporter) { EXPORTER }
  let(:spans) { exporter.finished_spans }
  let(:instrumentation) { OpenTelemetry::Instrumentation::ActiveStorage::Instrumentation.instance }
  let(:key_png) { 'sample.png' }
  let(:blob_png) do
    ActiveStorage::Blob.stub(:generate_unique_secure_token, key_png) do
      file = File.open("#{Dir.pwd}/test/fixtures/sample.png")
      ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: 'sample.png',
        content_type: 'image/png'
      )
    end
  end
  let(:key_pdf) { 'sample.pdf' }
  let(:blob_pdf) do
    ActiveStorage::Blob.stub(:generate_unique_secure_token, key_pdf) do
      file = File.open("#{Dir.pwd}/test/fixtures/sample.pdf")
      ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: 'sample.pdf',
        content_type: 'application/pdf'
      )
    end
  end

  before do
    AppConfig.initialize_app
    OpenTelemetry::Instrumentation::ActiveStorage::Railtie.unsubscribe
    exporter.reset
  end

  describe 'service_upload.active_storage' do
    describe 'with default configuration' do
      it 'generates a service_upload span' do
        with_subscription do
          _(blob_png).wont_be_nil
        end

        _(spans.length).must_equal(1)
        span = spans.find { |s| s.name == 'service_upload.active_storage' }

        _(span).wont_be_nil

        _(span.attributes['active_storage.key']).must_be_nil
        _(span.attributes['active_storage.checksum']).must_equal('9NwXsO4K/DCBz1BoXsIHiA==')
        _(span.attributes['active_storage.service']).must_equal('Disk')
      end
    end

    describe 'with custom configuration' do
      it 'with key: :include' do
        with_configuration(key: :include, disallowed_notification_payload_keys: []) do
          with_subscription do
            _(blob_png).wont_be_nil
          end
        end

        _(spans.length).must_equal(1)
        span = spans.find { |s| s.name == 'service_upload.active_storage' }

        _(span).wont_be_nil

        _(span.attributes['active_storage.key']).must_equal(key_png)
        _(span.attributes['active_storage.checksum']).must_equal('9NwXsO4K/DCBz1BoXsIHiA==')
        _(span.attributes['active_storage.service']).must_equal('Disk')
      end
    end
  end

  describe 'service_streaming_download.active_storage' do
    describe 'with default configuration' do
      it 'generates a service_streaming_download span' do
        with_subscription do
          blob_png.download { |chunk| _(chunk).must_be(:present?) }
        end

        _(spans.length).must_equal(2)
        span = spans.find { |s| s.name == 'service_streaming_download.active_storage' }

        _(span).wont_be_nil

        _(span.attributes['active_storage.key']).must_be_nil
        _(span.attributes['active_storage.service']).must_equal('Disk')
      end
    end

    describe 'with custom configuration' do
      it 'with key: :include' do
        with_configuration(key: :include, disallowed_notification_payload_keys: []) do
          with_subscription do
            blob_png.download { |chunk| _(chunk).must_be(:present?) }
          end
        end

        _(spans.length).must_equal(2)
        span = spans.find { |s| s.name == 'service_streaming_download.active_storage' }

        _(span).wont_be_nil

        _(span.attributes['active_storage.key']).must_equal(key_png)
        _(span.attributes['active_storage.service']).must_equal('Disk')
      end
    end
  end

  describe 'service_download_chunk.active_storage' do
    describe 'with default configuration' do
      it 'generates a service_download_chunk span' do
        with_subscription do
          return unless blob_png.respond_to?(:download_chunk)

          blob_png.download_chunk(0..1024)
        end

        _(spans.length).must_equal(2)
        span = spans.find { |s| s.name == 'service_download_chunk.active_storage' }

        _(span).wont_be_nil

        _(span.attributes['active_storage.key']).must_be_nil
        _(span.attributes['active_storage.service']).must_equal('Disk')
      end
    end

    describe 'with custom configuration' do
      it 'with key: :include' do
        with_configuration(key: :include, disallowed_notification_payload_keys: []) do
          with_subscription do
            return unless blob_png.respond_to?(:download_chunk)

            blob_png.download_chunk(0..1024)
          end
        end

        _(spans.length).must_equal(2)
        span = spans.find { |s| s.name == 'service_download_chunk.active_storage' }

        _(span).wont_be_nil

        _(span.attributes['active_storage.key']).must_equal(key_png)
        _(span.attributes['active_storage.service']).must_equal('Disk')
      end
    end
  end

  describe 'service_download.active_storage' do
    describe 'with default configuration' do
      it 'generates a service_download span' do
        with_subscription do
          _(blob_png.download).must_be(:present?)
        end

        _(spans.length).must_equal(2)
        span = spans.find { |s| s.name == 'service_download.active_storage' }

        _(span).wont_be_nil

        _(span.attributes['active_storage.key']).must_be_nil
        _(span.attributes['active_storage.service']).must_equal('Disk')
      end
    end

    describe 'with custom configuration' do
      it 'with key: :include' do
        with_configuration(key: :include, disallowed_notification_payload_keys: []) do
          with_subscription do
            _(blob_png.download).must_be(:present?)
          end
        end

        _(spans.length).must_equal(2)
        span = spans.find { |s| s.name == 'service_download.active_storage' }

        _(span).wont_be_nil

        _(span.attributes['active_storage.key']).must_equal(key_png)
        _(span.attributes['active_storage.service']).must_equal('Disk')
      end
    end
  end

  describe 'service_delete.active_storage' do
    describe 'with default configuration' do
      it 'generates a service_delete span' do
        with_subscription do
          blob_pdf.delete
        end

        _(spans.length).must_equal(2)
        span = spans.find { |s| s.name == 'service_delete.active_storage' }

        _(span).wont_be_nil
        _(span.attributes['active_storage.key']).must_be_nil
        _(span.attributes['active_storage.service']).must_equal('Disk')
      end
    end

    describe 'with custom configuration' do
      it 'with key: :include' do
        with_configuration(key: :include, disallowed_notification_payload_keys: []) do
          with_subscription do
            blob_pdf.delete
          end
        end

        _(spans.length).must_equal(2)
        span = spans.find { |s| s.name == 'service_delete.active_storage' }

        _(span).wont_be_nil
        _(span.attributes['active_storage.key']).must_equal(key_pdf)
        _(span.attributes['active_storage.service']).must_equal('Disk')
      end
    end
  end

  describe 'service_delete_prefixed.active_storage' do
    it 'generates a service_delete_prefixed span' do
      with_subscription do
        ActiveStorage::Blob.service.delete_prefixed('sample')
      end

      _(spans.length).must_equal(1)
      span = spans.find { |s| s.name == 'service_delete_prefixed.active_storage' }

      _(span).wont_be_nil

      _(span.attributes['active_storage.prefix']).must_equal('sample')
      _(span.attributes['active_storage.service']).must_equal('Disk')
    end
  end

  describe 'service_exist.active_storage' do
    describe 'with default configuration' do
      it 'generates a service_exist span' do
        with_subscription do
          _(ActiveStorage::Blob.service).wont_be(:exist?, 'key')
        end

        _(spans.length).must_equal(1)
        span = spans.find { |s| s.name == 'service_exist.active_storage' }

        _(span).wont_be_nil
        _(span.attributes['active_storage.key']).must_be_nil
        _(span.attributes['active_storage.service']).must_equal('Disk')
        _(span.attributes['active_storage.exist']).must_equal(false)
      end
    end

    describe 'with custom configuration' do
      it 'with key: :include' do
        with_configuration(key: :include, disallowed_notification_payload_keys: []) do
          with_subscription do
            _(ActiveStorage::Blob.service).wont_be(:exist?, 'key')
          end
        end

        _(spans.length).must_equal(1)
        span = spans.find { |s| s.name == 'service_exist.active_storage' }

        _(span).wont_be_nil
        _(span.attributes['active_storage.key']).must_equal('key')
        _(span.attributes['active_storage.service']).must_equal('Disk')
        _(span.attributes['active_storage.exist']).must_equal(false)
      end
    end
  end

  describe 'service_url.active_storage' do
    describe 'with default configuration' do
      it 'generates a service_url span' do
        with_subscription do
          _(blob_png.url).must_be(:present?)
        end

        _(spans.length).must_equal(2)
        span = spans.find { |s| s.name == 'service_url.active_storage' }

        _(span).wont_be_nil
        _(span.attributes['active_storage.key']).must_be_nil
        _(span.attributes['active_storage.service']).must_equal('Disk')
        _(span.attributes['active_storage.url']).must_be_nil
      end
    end

    describe 'with custom configuration' do
      it 'with key: :include' do
        with_configuration(key: :include, url: :include, disallowed_notification_payload_keys: []) do
          with_subscription do
            _(blob_png.url).must_be(:present?)
          end
        end

        _(spans.length).must_equal(2)
        span = spans.find { |s| s.name == 'service_url.active_storage' }

        _(span).wont_be_nil
        _(span.attributes['active_storage.key']).must_equal(key_png)
        _(span.attributes['active_storage.service']).must_equal('Disk')
        _(span.attributes['active_storage.url']).must_match(%r{^http://example\.com/rails/active_storage/disk/.*/sample.png})
      end
    end
  end

  describe 'preview.active_storage' do
    it 'generates a preview span' do
      with_subscription do
        _(blob_pdf.preview(resize_to_limit: [50, 50]).processed).must_be(:present?)
      end

      _(spans.length >= 4).must_equal(true)
      span = spans.find { |s| s.name == 'preview.active_storage' }

      _(span).wont_be_nil
    end
  end

  describe 'transform.active_storage' do
    it 'generates a transform span' do
      with_subscription do
        _(blob_png.variant(resize_to_limit: [50, 50]).processed).must_be(:present?)
      end

      _(spans.length).must_equal(5)
      span = spans.find { |s| s.name == 'transform.active_storage' }

      _(span).wont_be_nil
    end
  end

  # NOTE: The test for service_update_metadata.active_storage is skipped because this event is only for GCS service.
  # https://github.com/rails/rails/blob/fa9cf269191c5077de1abdd1e3f934fbeaf2a5d0/guides/source/active_support_instrumentation.md?plain=1#L928

  def with_configuration(values, &)
    original_config = instrumentation.instance_variable_get(:@config)
    modified_config = original_config.merge(values)
    instrumentation.instance_variable_set(:@config, modified_config)

    yield
  ensure
    instrumentation.instance_variable_set(:@config, original_config)
  end

  def with_subscription(&)
    OpenTelemetry::Instrumentation::ActiveStorage::Railtie.subscribe
    yield
  ensure
    OpenTelemetry::Instrumentation::ActiveStorage::Railtie.unsubscribe
  end
end
