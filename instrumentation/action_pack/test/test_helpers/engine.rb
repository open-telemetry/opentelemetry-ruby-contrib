# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module ExampleEngine
  class Engine < Rails::Engine; end
end

module ExampleEngine
  class ItemsController < ActionController::Base
    def show
      render plain: "item #{params[:id]}"
    end
  end
end
