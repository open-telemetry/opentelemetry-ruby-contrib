# frozen_string_literal: true

module Bookshelf
  class Routes < Hanami::Routes
    root { "Hello from Hanami" }

    get "/ok", to: ->(env) { [200, {}, ['actually ok']] }
  end
end
