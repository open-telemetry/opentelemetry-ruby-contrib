# frozen_string_literal: true

module Bookshelf
  class Routes < Hanami::Routes
    root { "Hello from Hanami" }

    get "/hanami", to: ->(env) { [200, {}, ["Hello from Hanami!"]] }
  end
end
