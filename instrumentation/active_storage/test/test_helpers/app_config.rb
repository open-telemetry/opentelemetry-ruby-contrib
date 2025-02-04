# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'active_storage/engine'

class TestApp < Rails::Application
  initializer :activestorage do
    ActiveStorage::Engine.config.active_storage.service_configurations = {
      test: {
        service: 'Disk',
        root: Dir.mktmpdir('active_storage_tests')
      }
    }
  end

  # Override to avoid reading config/database.yml
  def config.database_configuration
    {
      test: {
        adapter: 'sqlite3',
        database: ':memory:'
      }
    }
  end
end

require_relative 'test_previewer'

module AppConfig
  extend self

  def initialize_app
    new_app = TestApp.new
    new_app.config.secret_key_base = 'secret_key_base'

    # Ensure we don't see this Rails warning when testing
    new_app.config.eager_load = false
    new_app.config.active_support.to_time_preserves_timezone = :zone

    # Prevent tests from creating log/*.log
    level = ENV.fetch('OTEL_LOG_LEVEL', 'fatal').to_sym
    new_app.config.logger = Logger.new($stderr, level: level)
    new_app.config.log_level = level

    new_app.config.filter_parameters = [:param_to_be_filtered]

    new_app.config.hosts << 'example.org'

    new_app.config.active_storage.service = :test
    new_app.config.active_storage.previewers = [TestPreviewer]

    # Unfreeze values which may have been frozen on previous initializations.
    ActiveSupport::Dependencies.autoload_paths =
      ActiveSupport::Dependencies.autoload_paths.dup
    ActiveSupport::Dependencies.autoload_once_paths =
      ActiveSupport::Dependencies.autoload_once_paths.dup

    new_app.initialize!

    ActiveRecord::Migration.verbose = false
    ActiveRecord::Schema.define do
      create_table :active_storage_blobs, force: true do |t|
        t.string   :key,        null: false
        t.string   :filename,   null: false
        t.string   :content_type
        t.text     :metadata
        t.string   :service_name, null: false
        t.bigint   :byte_size,  null: false
        t.string   :checksum,   null: false
        t.datetime :created_at, null: false
        t.index [:key], unique: true
      end

      create_table :active_storage_attachments, force: true do |t|
        t.string     :name,     null: false
        t.references :record,   null: false, polymorphic: true, index: false
        t.references :blob,     null: false

        t.datetime :created_at, null: false
        t.index %i[record_type record_id name blob_id], name: 'index_active_storage_attachments_uniqueness', unique: true
      end
    end

    ActiveStorage::Current.url_options = { host: 'http://example.com' }

    if /^8\./.match?(Rails.version)
      # Since Rails 8.0, route drawing has been deferred to the first request.
      # See https://github.com/rails/rails/pull/52353
      # This forces route drawing to include ActiveStorage default routes.
      new_app.reload_routes_unless_loaded
    end

    new_app
  end
end
