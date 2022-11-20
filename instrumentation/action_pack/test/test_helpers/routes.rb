# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

def draw_routes(rails_app)
  rails_app.routes.draw do
    get '/ok', to: 'example#ok'
    get '/items/new', to: 'example#new_item'
    get '/items/:id', to: 'example#item'
    get '/query', to: 'example#query'
    get '/internal_server_error', to: 'example#internal_server_error'
  end
end
