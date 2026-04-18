# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# OTelBundlerPatch
module OTelBundlerPatch
  # Nested module to handle OpenTelemetry initialization logic
  module OTelInitializer
    @_otel_initialized = false

    OTEL_INSTRUMENTATION_MAP = {
      'action_mailer' => 'OpenTelemetry::Instrumentation::ActionMailer',
      'action_pack' => 'OpenTelemetry::Instrumentation::ActionPack',
      'action_view' => 'OpenTelemetry::Instrumentation::ActionView',
      'active_job' => 'OpenTelemetry::Instrumentation::ActiveJob',
      'active_model_serializers' => 'OpenTelemetry::Instrumentation::ActiveModelSerializers',
      'active_record' => 'OpenTelemetry::Instrumentation::ActiveRecord',
      'active_storage' => 'OpenTelemetry::Instrumentation::ActiveStorage',
      'active_support' => 'OpenTelemetry::Instrumentation::ActiveSupport',
      'anthropic' => 'OpenTelemetry::Instrumentation::Anthropic',
      'aws_lambda' => 'OpenTelemetry::Instrumentation::AwsLambda',
      'aws_sdk' => 'OpenTelemetry::Instrumentation::AwsSdk',
      'bunny' => 'OpenTelemetry::Instrumentation::Bunny',
      'concurrent_ruby' => 'OpenTelemetry::Instrumentation::ConcurrentRuby',
      'dalli' => 'OpenTelemetry::Instrumentation::Dalli',
      'delayed_job' => 'OpenTelemetry::Instrumentation::DelayedJob',
      'ethon' => 'OpenTelemetry::Instrumentation::Ethon',
      'excon' => 'OpenTelemetry::Instrumentation::Excon',
      'faraday' => 'OpenTelemetry::Instrumentation::Faraday',
      'grape' => 'OpenTelemetry::Instrumentation::Grape',
      'graphql' => 'OpenTelemetry::Instrumentation::GraphQL',
      'grpc' => 'OpenTelemetry::Instrumentation::Grpc',
      'gruf' => 'OpenTelemetry::Instrumentation::Gruf',
      'http' => 'OpenTelemetry::Instrumentation::HTTP',
      'http_client' => 'OpenTelemetry::Instrumentation::HttpClient',
      'httpx' => 'OpenTelemetry::Instrumentation::HTTPX',
      'koala' => 'OpenTelemetry::Instrumentation::Koala',
      'lmdb' => 'OpenTelemetry::Instrumentation::LMDB',
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
      'resque' => 'OpenTelemetry::Instrumentation::Resque',
      'restclient' => 'OpenTelemetry::Instrumentation::RestClient',
      'ruby_kafka' => 'OpenTelemetry::Instrumentation::RubyKafka',
      'sidekiq' => 'OpenTelemetry::Instrumentation::Sidekiq',
      'sinatra' => 'OpenTelemetry::Instrumentation::Sinatra',
      'trilogy' => 'OpenTelemetry::Instrumentation::Trilogy'
    }.freeze
    private_constant :OTEL_INSTRUMENTATION_MAP

    def self._otel_detect_resource_from_env
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

    def self._otel_determine_enabled_instrumentation
      env = ENV['OTEL_RUBY_ENABLED_INSTRUMENTATIONS'].to_s

      env.split(',').map { |instrumentation| OTEL_INSTRUMENTATION_MAP[instrumentation] }
    end

    def self._otel_check_for_bundled_otel_gems
      bundled_otel_gems = Bundler.definition.dependencies.select do |dep|
        dep.name.start_with?('opentelemetry-')
      end

      return if bundled_otel_gems.empty?

      gem_names = bundled_otel_gems.map(&:name).sort.join(', ')
      warn '[OpenTelemetry] WARNING: Detected OpenTelemetry gems in your Gemfile: ' \
           "#{gem_names}. When using opentelemetry-auto-instrumentation, OpenTelemetry gems are loaded " \
           'from the opentelemetry-auto-instrumentation gem path, NOT from your bundle. The gem versions ' \
           'in your Gemfile/Gemfile.lock are not used and may cause version conflicts or ' \
           'unexpected behavior. Please remove these gems from your Gemfile when using ' \
           'opentelemetry-auto-instrumentation.'
    rescue StandardError => e
      warn "[OpenTelemetry] WARNING: Unable to check Gemfile for OpenTelemetry gems: #{e.message}" if ENV['OTEL_RUBY_AUTO_INSTRUMENTATION_DEBUG'] == 'true'
    end

    def self._otel_require_otel
      return if @_otel_initialized

      @_otel_initialized = true

      begin
        _otel_check_for_bundled_otel_gems

        required_instrumentation = _otel_determine_enabled_instrumentation

        resource = _otel_detect_resource_from_env

        OpenTelemetry::SDK.configure do |c|
          c.resource = resource
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
    OTelInitializer._otel_require_otel
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
require 'opentelemetry-metrics-sdk'
require 'opentelemetry-logs-sdk'
require 'opentelemetry-exporter-otlp'
require 'opentelemetry-exporter-otlp-metrics'
require 'opentelemetry-exporter-otlp-logs'
require 'opentelemetry-instrumentation-all'

resource_detectors = ENV['OTEL_RUBY_RESOURCE_DETECTORS'].to_s
require 'opentelemetry-resource-detector-container' if resource_detectors.include?('container')
require 'opentelemetry-resource-detector-azure' if resource_detectors.include?('azure')
require 'opentelemetry-resource-detector-aws' if resource_detectors.include?('aws')

Bundler::Runtime.prepend(OTelBundlerPatch)

Bundler.require if ENV['OTEL_RUBY_REQUIRE_BUNDLER'] == 'true'
