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
    get '/internal_page_not_found', to: 'example#internal_page_not_found'
    get '/internal_invalid_auth', to: 'example#internal_invalid_auth'
  end
end
