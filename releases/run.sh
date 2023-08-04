#!/bin/bash

set -e

echo "Installing latest version of published gems and running tests"

bundle install && bundle exec rake
