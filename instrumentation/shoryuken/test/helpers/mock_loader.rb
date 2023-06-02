# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'shoryuken/launcher'

class MockLoader
  include Shoryuken::Util

  attr_reader :launcher

  def initialize
    fire_event(:startup)
    Shoryuken.add_group('default', Shoryuken.options[:concurrency])
    @launcher = Shoryuken::Launcher.new
  end

  def fetcher
    manager.instance_variable_get(:@fetcher)
  end

  def manager
    launcher.instance_variable_get(:@managers).first
  end
end
