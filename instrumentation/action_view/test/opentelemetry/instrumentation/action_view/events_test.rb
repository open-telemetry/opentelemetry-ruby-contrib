# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'
require 'action_controller/test_case'

class ActionViewEventsTest < ActionController::TestCase
  tests PostsController

  def exporter
    EXPORTER
  end

  def spans
    exporter.finished_spans
  end

  def setup
    super
    @routes = TestApp.routes
    exporter.reset
  end

  def test_render_template
    get :index

    template_spans = spans.select { |s| s.name == 'render_template.action_view' }

    span = template_spans.first
    assert_equal :internal, span.kind
    assert_includes span.attributes['identifier'], 'posts/index'
    assert_includes span.attributes['layout'], 'application'
  end

  def test_render_template_without_layout
    get :api

    template_spans = spans.select { |s| s.name == 'render_template.action_view' }

    span = template_spans.first
    assert_includes span.attributes['identifier'], 'posts/api'
  end

  def test_render_partial
    get :with_partial

    partial_spans = spans.select { |s| s.name == 'render_partial.action_view' }
    assert_not_empty partial_spans

    span = partial_spans.first
    assert_equal :internal, span.kind
    assert_includes span.attributes['identifier'], '_form'
  end

  def test_render_collection
    get :with_collection

    collection_spans = spans.select { |s| s.name == 'render_collection.action_view' }

    span = collection_spans.first
    assert_equal :internal, span.kind
    assert_includes span.attributes['identifier'], '_item'
    assert_equal 3, span.attributes['count']
  end

  def test_render_template_with_local_params
    get :with_locals

    collection_spans = spans.select { |s| s.name == 'render_template.action_view' }

    span = collection_spans.first
    assert_equal :internal, span.kind
    assert_includes span.attributes['identifier'], 'posts/with_locals'
    refute_includes span.attributes, 'locals'
  end

  def test_render_layout
    get :index

    layout_spans = spans.select { |s| s.name == 'render_layout.action_view' }

    span = layout_spans.first
    assert_equal :internal, span.kind
    assert_includes span.attributes['identifier'], 'application'
  end
end
