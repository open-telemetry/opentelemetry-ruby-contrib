# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require_relative '../../../../lib/opentelemetry/instrumentation/sidekiq'

describe OpenTelemetry::Instrumentation::Sidekiq::Instrumentation do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Sidekiq::Instrumentation.instance }

  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Sidekiq'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe 'compatible' do
    it 'when older gem version installed' do
      stub_const('::Sidekiq::VERSION', '4.2.8')
      _(instrumentation.compatible?).must_equal false
    end

    it 'when future gem version installed' do
      _(instrumentation.compatible?).must_equal true
    end
  end

  describe '#install' do
    before do
      @sidekiq_config = if Sidekiq.respond_to?(:client_middleware) # Sidekiq < 7.0.0
                          Sidekiq
                        else # Sidekiq >= 7.0.0
                          Sidekiq.default_configuration
                        end

      @orig_client_wares = @sidekiq_config.client_middleware.entries.dup
      @orig_server_wares = @sidekiq_config.server_middleware.entries.dup
      @orig_testin_wares = Sidekiq::Testing.server_middleware.entries.dup
    end

    after do
      # Force re-install of instrumentation
      instrumentation.instance_variable_set(:@installed, false)

      # Reset the middleware chains
      @sidekiq_config.client_middleware.instance_variable_set(:@entries, @orig_client_wares)
      @sidekiq_config.server_middleware.instance_variable_set(:@entries, @orig_server_wares)
      Sidekiq::Testing.server_middleware.instance_variable_set(:@entries, @orig_testin_wares)
    end

    describe 'configuring the Sidekiq Client' do
      before do
        Sidekiq.stub(:server?, false) do
          Sidekiq.configure_client do |config|
            config.client_middleware do |chain|
              chain.add(Frontkiq::SweetClientMiddleware)
            end
          end
        end
      end

      it 'prepends the Client::TracerMiddleware to the Sidekiq Client middleware chain' do
        Sidekiq.stub(:server?, false) do
          instrumentation.install
        end

        middlewares = @sidekiq_config.client_middleware.entries
        _(middlewares.first.klass).must_equal(OpenTelemetry::Instrumentation::Sidekiq::Middlewares::Client::TracerMiddleware)
        _(middlewares.last.klass).must_equal(Frontkiq::SweetClientMiddleware)
      end
    end

    describe 'configuring the Sidekiq Server' do
      before do
        Sidekiq.stub(:server?, true) do
          Sidekiq.configure_server do |config|
            config.client_middleware do |chain|
              chain.add(Frontkiq::SweetClientMiddleware)
            end
            config.server_middleware do |chain|
              chain.add(Frontkiq::SweetServerMiddleware)
            end
          end

          Sidekiq::Testing.server_middleware do |chain|
            chain.add(Frontkiq::SweetServerMiddleware)
          end
        end
      end

      it 'prepends the Client::TracerMiddleware to the Sidekiq Client middleware chain' do
        Sidekiq.stub(:server?, true) do
          instrumentation.install
        end

        middlewares = @sidekiq_config.client_middleware.entries
        _(middlewares.first.klass).must_equal(OpenTelemetry::Instrumentation::Sidekiq::Middlewares::Client::TracerMiddleware)
        _(middlewares.last.klass).must_equal(Frontkiq::SweetClientMiddleware)
      end

      it 'prepends the Server::TracerMiddleware to the Sidekiq Server middleware chain' do
        Sidekiq.stub(:server?, true) do
          instrumentation.install
        end

        middlewares = @sidekiq_config.server_middleware.entries
        _(middlewares.first.klass).must_equal(OpenTelemetry::Instrumentation::Sidekiq::Middlewares::Server::TracerMiddleware)
        _(middlewares.last.klass).must_equal(Frontkiq::SweetServerMiddleware)

        testing_wares = Sidekiq::Testing.server_middleware.entries
        _(testing_wares.first.klass).must_equal(OpenTelemetry::Instrumentation::Sidekiq::Middlewares::Server::TracerMiddleware)
        _(testing_wares.last.klass).must_equal(Frontkiq::SweetServerMiddleware)
      end
    end
  end
end
