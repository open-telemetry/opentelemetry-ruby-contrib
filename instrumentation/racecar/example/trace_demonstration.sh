#!/usr/bin/env bash

bundle check || bundle install
bundle exec racecar --require consumer --require tracing Consumer
