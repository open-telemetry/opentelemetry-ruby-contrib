# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

def draw_routes(rails_app)
  rails_app.routes.draw do
    get '/ok', to: 'example#ok'
    get '/ok-symbol', to: ExampleController.action(:ok)
    get '/items/new', to: 'example#new_item'
    get '/items/:id', to: 'example#item'
    get '/internal_server_error', to: 'example#internal_server_error'
    mount ExampleEngine::Engine, at: '/engine'
  end

  ExampleEngine::Engine.routes.draw do
    get '/items/:id', to: 'example_engine/items#show'
  end
end
