# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# OTelBundlerPatch
module OTelBundlerPatch
  # Nested module to handle OpenTelemetry initialization logic
  module OTelInitializer
    @initialized = false

    OTEL_INSTRUMENTATION_MAP = {
      'gruf' => 'OpenTelemetry::Instrumentation::Gruf',
      'trilogy' => 'OpenTelemetry::Instrumentation::Trilogy',
      'active_support' => 'OpenTelemetry::Instrumentation::ActiveSupport',
      'action_pack' => 'OpenTelemetry::Instrumentation::ActionPack',
      'active_job' => 'OpenTelemetry::Instrumentation::ActiveJob',
      'active_record' => 'OpenTelemetry::Instrumentation::ActiveRecord',
      'action_view' => 'OpenTelemetry::Instrumentation::ActionView',
      'action_mailer' => 'OpenTelemetry::Instrumentation::ActionMailer',
      'aws_sdk' => 'OpenTelemetry::Instrumentation::AwsSdk',
      'aws_lambda' => 'OpenTelemetry::Instrumentation::AwsLambda',
      'bunny' => 'OpenTelemetry::Instrumentation::Bunny',
      'lmdb' => 'OpenTelemetry::Instrumentation::LMDB',
      'http' => 'OpenTelemetry::Instrumentation::HTTP',
      'koala' => 'OpenTelemetry::Instrumentation::Koala',
      'active_model_serializers' => 'OpenTelemetry::Instrumentation::ActiveModelSerializers',
      'concurrent_ruby' => 'OpenTelemetry::Instrumentation::ConcurrentRuby',
      'dalli' => 'OpenTelemetry::Instrumentation::Dalli',
      'delayed_job' => 'OpenTelemetry::Instrumentation::DelayedJob',
      'ethon' => 'OpenTelemetry::Instrumentation::Ethon',
      'excon' => 'OpenTelemetry::Instrumentation::Excon',
      'faraday' => 'OpenTelemetry::Instrumentation::Faraday',
      'grape' => 'OpenTelemetry::Instrumentation::Grape',
      'graphql' => 'OpenTelemetry::Instrumentation::GraphQL',
      'http_client' => 'OpenTelemetry::Instrumentation::HttpClient',
      'mongo' => 'OpenTelemetry::Instrumentation::Mongo',
      'mysql2' => 'OpenTelemetry::Instrumentation::Mysql2',
      'net_http' => 'OpenTelemetry::Instrumentation::Net::HTTP',
      'pg' => 'OpenTelemetry::Instrumentation::PG',
      'que' => 'OpenTelemetry::Instrumentation::Que',
      'racecar' => 'OpenTelemetry::Instrumentation::Racecar',
      'rack' => 'OpenTelemetry::Instrumentation::Rack',
      'rails' => 'OpenTelemetry::Instrumentation::Rails',
      'rake' => 'OpenTelemetry::Instrumentation::Rake',
      'rdkafka' => 'OpenTelemetry::Instrumentation::Rdkafka',
      'redis' => 'OpenTelemetry::Instrumentation::Redis',
      'restclient' => 'OpenTelemetry::Instrumentation::RestClient',
      'resque' => 'OpenTelemetry::Instrumentation::Resque',
      'ruby_kafka' => 'OpenTelemetry::Instrumentation::RubyKafka',
      'sidekiq' => 'OpenTelemetry::Instrumentation::Sidekiq',
      'sinatra' => 'OpenTelemetry::Instrumentation::Sinatra'
    }.freeze

    def self.detect_resource_from_env
      env = ENV['OTEL_RUBY_RESOURCE_DETECTORS'].to_s
      additional_resource = ::OpenTelemetry::SDK::Resources::Resource.create({})

      resource_map = {
        'container' => (defined?(::OpenTelemetry::Resource::Detector::Container) ? ::OpenTelemetry::Resource::Detector::Container : nil),
        'azure' => (defined?(::OpenTelemetry::Resource::Detector::Azure) ? ::OpenTelemetry::Resource::Detector::Azure : nil),
        'aws' => (defined?(::OpenTelemetry::Resource::Detector::AWS) ? ::OpenTelemetry::Resource::Detector::AWS : nil)
      }

      env.split(',').each do |detector|
        additional_resource = additional_resource.merge(resource_map[detector].detect) if resource_map[detector]
      end

      additional_resource
    end

    def self.determine_enabled_instrumentation
      env = ENV['OTEL_RUBY_ENABLED_INSTRUMENTATIONS'].to_s

      env.split(',').map { |instrumentation| OTEL_INSTRUMENTATION_MAP[instrumentation] }
    end

    def self.require_otel
      return if @initialized

      @initialized = true

      begin
        required_instrumentation = determine_enabled_instrumentation

        OpenTelemetry::SDK.configure do |c|
          c.resource = detect_resource_from_env
          if required_instrumentation.empty?
            c.use_all
          else
            required_instrumentation.each do |instrumentation|
              c.use instrumentation
            end
          end
        end
        OpenTelemetry.logger.info { 'Auto-instrumentation initialized' }
      rescue StandardError => e
        warn "Auto-instrumentation failed to initialize. Error: #{e.message}"
      end
    end
  end

  def require(...)
    super
    OTelInitializer.require_otel
  end
end

require 'bundler'

# /otel-auto-instrumentation-ruby is default path for otel operator (ruby.go)
# If requires different gem path to load gem, set env OTEL_RUBY_ADDITIONAL_GEM_PATH
gem_path = ENV['OTEL_RUBY_ADDITIONAL_GEM_PATH'] || '/otel-auto-instrumentation-ruby' || Gem.dir
$stdout.puts "Loading the gem path from #{gem_path}" if ENV['OTEL_RUBY_AUTO_INSTRUMENTATION_DEBUG'] == 'true'

# Load OpenTelemetry components and their dependencies
# googleapis-common-protos-types and google-protobuf are dependencies for otlp exporters
loaded_library_file_path = Dir.glob("#{gem_path}/gems/*").select do |file_path|
  file_path.include?('opentelemetry') ||
    file_path.include?('googleapis-common-protos-types') ||
    file_path.include?('google-protobuf')
end

# unshift file_path add opentelemetry component at the top of $LOAD_PATH
loaded_library_file_path.each { |file_path| $LOAD_PATH.unshift("#{file_path}/lib") }
$stdout.puts "$LOAD_PATH after unshift: #{$LOAD_PATH.join(',')}" if ENV['OTEL_RUBY_AUTO_INSTRUMENTATION_DEBUG'] == 'true'

# These are required for the prepend OTelBundlerPatch to fetch OpenTelemetry::SDK.configure
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-all'
require 'opentelemetry-exporter-otlp'

resource_detectors = ENV['OTEL_RUBY_RESOURCE_DETECTORS'].to_s
require 'opentelemetry-resource-detector-container' if resource_detectors.include?('container')
require 'opentelemetry-resource-detector-azure' if resource_detectors.include?('azure')
require 'opentelemetry-resource-detector-aws' if resource_detectors.include?('aws')

Bundler::Runtime.prepend(OTelBundlerPatch)

Bundler.require if ENV['OTEL_RUBY_REQUIRE_BUNDLER'] == 'true'
