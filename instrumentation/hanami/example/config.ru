# frozen_string_literal: true

require './server'

require '../example/config/app'
require '../example/config/routes'
require '../example/config/settings'

Hanami.prepare

run Hanami.app
