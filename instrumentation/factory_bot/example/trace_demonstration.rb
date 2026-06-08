#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'opentelemetry-api'
  gem 'opentelemetry-instrumentation-base'
  gem 'opentelemetry-instrumentation-factory_bot', path: '../'
  gem 'opentelemetry-sdk'
  gem 'factory_bot'
end

require 'opentelemetry-api'
require 'opentelemetry-sdk'
require 'opentelemetry-instrumentation-factory_bot'
require 'active_support/core_ext/time'
require 'factory_bot'

# Export traces to console by default
ENV['OTEL_TRACES_EXPORTER'] ||= 'console'

OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::FactoryBot'
end

# Define a simple User struct for the factory
User = Struct.new(:name, :email, keyword_init: true)

# Define a factory
FactoryBot.define do
  factory :user do
    name { 'Test User' }
    email { 'test@example.com' }

    initialize_with { User.new(**attributes) }
  end
end

# Basic examples demonstrating FactoryBot instrumentation
puts "=== FactoryBot OpenTelemetry Instrumentation Example ==="
puts

puts "1. Building a single user with FactoryBot.build:"
user = FactoryBot.build(:user)
puts "   Created: #{user.inspect}"
puts

puts "2. Building a list of users with FactoryBot.build_list:"
users = FactoryBot.build_list(:user, 3)
puts "   Created #{users.size} users"
puts

puts "3. Building stubbed users with FactoryBot.build_stubbed:"
stubbed_user = FactoryBot.build_stubbed(:user)
puts "   Created stubbed user: #{stubbed_user.inspect}"
puts

puts "4. Getting attributes with FactoryBot.attributes_for:"
attrs = FactoryBot.attributes_for(:user)
puts "   Attributes: #{attrs.inspect}"
puts

puts "=== All operations created OpenTelemetry spans shown above ==="
