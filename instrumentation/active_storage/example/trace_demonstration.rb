# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'rails'
  gem 'sqlite3'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-instrumentation-active_support', path: '../../active_support'
  gem 'opentelemetry-instrumentation-active_storage', path: '../'
end

require 'active_storage/engine'

# TraceApp is a minimal Rails application inspired by the Rails
# bug report template for action controller.
# The configuration is compatible with Rails 6.0
class TraceApp < Rails::Application
  config.root = __dir__
  config.hosts << 'example.org'
  credentials.secret_key_base = 'secret_key_base'

  config.eager_load = false

  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger

  config.active_storage.service = :development
  config.active_storage.service_configurations = {
    development: {
      service: 'Disk',
      root: Dir.mktmpdir('active_storage_tests')
    }
  }

  # Override to avoid reading config/database.yml
  def config.database_configuration
    {
      development: {
        adapter: 'sqlite3',
        database: ':memory:'
      }
    }
  end
end

# Simple setup for demonstration purposes, simple span processor should not be
# used in a production environment
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
  OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
)

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::ActiveStorage'
  c.add_span_processor(span_processor)
end

Rails.application.initialize!

ActiveRecord::Base.logger = Logger.new(STDOUT)
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

ActiveStorage::Blob.create_and_upload!(
  io: StringIO.new('test file content'),
  filename: 'test.txt',
  content_type: 'text/plain'
)

# To run this example run the `ruby` command with this file
# Example: ruby trace_demonstration.rb
