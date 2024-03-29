# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'sidekiq/cli'
require 'sidekiq/launcher'

class MockLoader
  attr_reader :launcher

  def initialize
    @launcher = Sidekiq::Launcher.new(Sidekiq.default_configuration)
    @launcher.fire_event(:startup)
  end

  def poller
    launcher.poller
  end

  def manager
    launcher.managers.first
  end
end
