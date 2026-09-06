# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/helpers/sql'

describe OpenTelemetry::Helpers::Sql do
  describe 'when using implicit contexts' do
    it 'manages shared attributes with child contexts' do
      actual_attrs = nil
      actual_context = nil

      shared_attrs = { 'db.operation' => 'foo' }

      OpenTelemetry::Helpers::Sql.with_attributes(shared_attrs.dup) do |_, child|
        actual_attrs = OpenTelemetry::Helpers::Sql.attributes
        actual_context = child
      end

      _(OpenTelemetry::Helpers::Sql.attributes(actual_context)).must_equal(shared_attrs)
      _(actual_attrs).must_equal(shared_attrs)
    end

    it 'provides immediate access to shared attributes' do
      actual_attrs = nil
      shared_attrs = { 'db.operation' => 'foo' }

      OpenTelemetry::Helpers::Sql.with_attributes(shared_attrs.dup) do |attrs, _|
        actual_attrs = attrs
      end

      _(actual_attrs).must_equal(shared_attrs)
    end

    it 'manages shared attributes using an implicit context' do
      shared_attrs = { 'db.operation' => 'foo' }
      actual_attrs = nil
      actual_context = OpenTelemetry::Helpers::Sql.context_with_attributes(shared_attrs.dup)
      OpenTelemetry::Context.with_current(actual_context) do
        actual_attrs = OpenTelemetry::Helpers::Sql.attributes
      end

      _(actual_context).wont_equal(OpenTelemetry::Context.current)
      _(actual_attrs).must_equal(shared_attrs)
    end
  end

  describe 'when using explicit contexts' do
    it 'manages shared attributes using a child child contexts' do
      actual_attrs = nil
      actual_context = nil

      shared_attrs = { 'db.operation' => 'foo' }

      root_context = OpenTelemetry::Context.empty

      OpenTelemetry::Helpers::Sql.with_attributes(shared_attrs.dup) do |_, child|
        actual_attrs = OpenTelemetry::Helpers::Sql.attributes(child)
        actual_context = child
      end

      _(actual_context).wont_equal(root_context)
      _(actual_attrs).must_equal(shared_attrs)
    end

    it 'manages shared attributes using a provided context' do
      shared_attrs = { 'db.operation' => 'foo' }

      root_context = OpenTelemetry::Context.empty
      actual_context = OpenTelemetry::Helpers::Sql.context_with_attributes(shared_attrs.dup, parent_context: root_context)
      actual_attrs = OpenTelemetry::Helpers::Sql.attributes(actual_context)

      _(actual_context).wont_equal(root_context)
      _(actual_attrs).must_equal(shared_attrs)
    end

    describe 'given the incorrect context' do
      it 'attempts to find shared attributes' do
        actual_attrs = nil
        actual_context = nil

        shared_attrs = { 'db.operation' => 'foo' }

        root_context = OpenTelemetry::Context.empty

        OpenTelemetry::Helpers::Sql.with_attributes(shared_attrs.dup) do |_, child|
          actual_attrs = OpenTelemetry::Helpers::Sql.attributes(root_context)
          actual_context = child
        end

        _(actual_context).wont_equal(root_context)
        _(actual_attrs).must_be_empty
      end
    end
  end
end
