# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'opentelemetry/instrumentation/puma/plugin'

describe OpenTelemetry::Instrumentation::Puma::Plugin do
  before do
    conf = Puma::Configuration.new do |user_config|
      user_config.app do |_env|
        [200, {}, ['hello world']]
      end
      user_config.bind("tcp://127.0.0.1:#{unique_port}")
      user_config.plugin 'opentelemetry'
    end
    @launcher = Puma::Launcher.new(conf, log_writer: Puma::LogWriter.null)
  end

  after do
    @launcher&.stop
  end

  it 'flushes providers on stop' do
    event_name = ::Puma::Const::PUMA_VERSION < '7' ? :on_booted : :after_booted
    @launcher.events.public_send(event_name) do
      sleep 1.1 unless mri?
      @launcher.stop
    end
    @launcher.run
    sleep 1 unless mri?

    _(OpenTelemetry.tracer_provider.instance_variable_get(:@stopped)).must_equal(true)
    _(OpenTelemetry.meter_provider.instance_variable_get(:@stopped)).must_equal(true) if OpenTelemetry.respond_to?(:meter_provider)
    _(OpenTelemetry.logger_provider.instance_variable_get(:@stopped)).must_equal(true) if OpenTelemetry.respond_to?(:logger_provider)
  end

  private

  def unique_port
    TCPServer.open('127.0.0.1', 0) do |server|
      server.connect_address.ip_port
    end
  end

  def mri?
    RUBY_ENGINE == 'ruby'
  end
end
