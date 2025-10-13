# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/factory_bot'

# Define simple test classes for factories
User = Struct.new(:id, :name, :email, keyword_init: true)
Admin = Struct.new(:id, :name, :email, :admin, keyword_init: true)

describe OpenTelemetry::Instrumentation::FactoryBot do
  let(:instrumentation) { OpenTelemetry::Instrumentation::FactoryBot::Instrumentation.instance }
  let(:exporter) { EXPORTER }

  before do
    exporter.reset
    instrumentation.install({})
    FactoryBot.reload

    FactoryBot.define do
      factory :user do
        sequence(:name) { |n| "User #{n}" }
        sequence(:email) { |n| "user#{n}@example.com" }

        initialize_with { new(**attributes) }
      end

      factory :admin do
        sequence(:name) { |n| "Admin #{n}" }
        sequence(:email) { |n| "admin#{n}@example.com" }
        admin { true }

        initialize_with { new(**attributes) }
      end
    end
  end

  after do
    instrumentation.instance_variable_set(:@installed, false)
  end

  # Basic instrumentation tests
  it 'has #name' do
    _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::FactoryBot'
  end

  it 'has #version' do
    _(instrumentation.version).wont_be_nil
    _(instrumentation.version).wont_be_empty
  end

  describe '#install' do
    it 'accepts argument' do
      _(instrumentation.install({})).must_equal(true)
    end
  end

  describe '#compatible?' do
    it 'returns true for FactoryBot 4.0+' do
      _(instrumentation.compatible?).must_equal(true)
    end
  end

  # Strategy tests - FactoryBot.build
  describe 'FactoryBot.build' do
    it 'creates a span for FactoryBot.build' do
      FactoryBot.build(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.build') }
      _(span).wont_be_nil
    end

    it 'sets factory_bot.strategy attribute to build' do
      FactoryBot.build(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.build') }
      _(span.attributes['factory_bot.strategy']).must_equal 'build'
    end

    it 'sets factory_bot.factory_name attribute' do
      FactoryBot.build(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.build') }
      _(span.attributes['factory_bot.factory_name']).must_equal 'user'
    end

    it 'sets factory_bot.traits to empty array when no traits' do
      FactoryBot.build(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.build') }
      _(span.attributes['factory_bot.traits']).must_equal []
    end
  end

  # Strategy tests - FactoryBot.build_stubbed
  describe 'FactoryBot.build_stubbed' do
    it 'creates a span for FactoryBot.build_stubbed' do
      FactoryBot.build_stubbed(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.build_stubbed') }
      _(span).wont_be_nil
    end

    it 'sets factory_bot.strategy attribute to stub' do
      FactoryBot.build_stubbed(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.build_stubbed') }
      _(span.attributes['factory_bot.strategy']).must_equal 'stub'
    end

    it 'sets factory_bot.factory_name attribute' do
      FactoryBot.build_stubbed(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.build_stubbed') }
      _(span.attributes['factory_bot.factory_name']).must_equal 'user'
    end

    it 'sets factory_bot.traits to empty array when no traits' do
      FactoryBot.build_stubbed(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.build_stubbed') }
      _(span.attributes['factory_bot.traits']).must_equal []
    end
  end

  # Strategy tests - FactoryBot.attributes_for
  describe 'FactoryBot.attributes_for' do
    it 'creates a span for FactoryBot.attributes_for' do
      FactoryBot.attributes_for(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.attributes_for') }
      _(span).wont_be_nil
    end

    it 'sets factory_bot.strategy attribute to attributes_for' do
      FactoryBot.attributes_for(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.attributes_for') }
      _(span.attributes['factory_bot.strategy']).must_equal 'attributes_for'
    end

    it 'sets factory_bot.factory_name attribute' do
      FactoryBot.attributes_for(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.attributes_for') }
      _(span.attributes['factory_bot.factory_name']).must_equal 'user'
    end

    it 'sets factory_bot.traits to empty array when no traits' do
      FactoryBot.attributes_for(:user)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.attributes_for') }
      _(span.attributes['factory_bot.traits']).must_equal []
    end
  end

  # Batch operation tests
  describe 'FactoryBot.build_list' do
    it 'creates spans for each item in FactoryBot.build_list' do
      FactoryBot.build_list(:user, 3)

      spans = exporter.finished_spans.select { |s| s.name.include?('FactoryBot.build') }
      _(spans.size).must_equal 3
    end

    it 'sets correct attributes on each span' do
      FactoryBot.build_list(:user, 3)

      spans = exporter.finished_spans.select { |s| s.name.include?('FactoryBot.build') }
      spans.each do |span|
        _(span.attributes['factory_bot.strategy']).must_equal 'build'
        _(span.attributes['factory_bot.factory_name']).must_equal 'user'
        _(span.attributes['factory_bot.traits']).must_equal []
      end
    end
  end

  describe 'FactoryBot.build_pair' do
    it 'creates spans for each item in FactoryBot.build_pair' do
      FactoryBot.build_pair(:user)

      spans = exporter.finished_spans.select { |s| s.name.include?('FactoryBot.build') }
      _(spans.size).must_equal 2
    end

    it 'sets correct attributes on each span' do
      FactoryBot.build_pair(:user)

      spans = exporter.finished_spans.select { |s| s.name.include?('FactoryBot.build') }
      spans.each do |span|
        _(span.attributes['factory_bot.strategy']).must_equal 'build'
        _(span.attributes['factory_bot.factory_name']).must_equal 'user'
        _(span.attributes['factory_bot.traits']).must_equal []
      end
    end
  end

  # Test multiple factory types
  describe 'multiple factories' do
    it 'correctly identifies different factories' do
      FactoryBot.build(:user)
      FactoryBot.build(:admin)

      spans = exporter.finished_spans.select { |s| s.name.include?('FactoryBot.build') }
      factory_names = spans.map { |s| s.attributes['factory_bot.factory_name'] }

      _(factory_names).must_include 'user'
      _(factory_names).must_include 'admin'
    end
  end

  # Traits tests
  describe 'traits' do
    before do
      FactoryBot.define do
        factory :user_with_traits, class: User do
          sequence(:name) { |n| "User #{n}" }
          sequence(:email) { |n| "user#{n}@example.com" }

          trait :premium
          trait :verified

          initialize_with { new(**attributes) }
        end
      end
    end

    it 'sets factory_bot.traits to empty array when no traits used' do
      FactoryBot.build(:user_with_traits)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.build') }
      _(span.attributes['factory_bot.traits']).must_equal []
    end

    it 'sets factory_bot.traits as array with multiple traits' do
      FactoryBot.build(:user_with_traits, :premium, :verified)

      span = exporter.finished_spans.find { |s| s.name.include?('FactoryBot.build') }
      _(span.attributes['factory_bot.traits']).must_equal %w[premium verified]
    end
  end
end
