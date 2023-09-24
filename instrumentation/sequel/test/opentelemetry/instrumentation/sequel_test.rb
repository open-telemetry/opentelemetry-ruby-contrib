# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Instrumentation::Sequel do
  let(:instrumentation) { OpenTelemetry::Instrumentation::Sequel::Instrumentation.instance }
  let(:exporter) { EXPORTER }
  let(:memory_database) { Sequel.connect('sqlite::memory:') }
  let(:db_file) { Tempfile.new }
  let(:file_database) { Sequel.connect("sqlite://#{db_file.path}") }
  let(:model) { Class.new(Sequel::Model(:documents)) }

  before do
    instrumentation.install
    memory_database.extension :opentelemetry
    memory_database.create_table!(:documents) do
      primary_key :id
      String :title
    end
    file_database.extension :opentelemetry
    model # Instantiate the model so that it doesn't interfere with further calls

    exporter.reset
  end

  describe 'database methods' do
    it 'before query' do
      _(exporter.finished_spans).must_be_empty
    end

    it 'traces dataset executes' do
      memory_database['SELECT 1'].all

      _(exporter.finished_spans.size).must_equal 1
      _(exporter.finished_spans.map(&:name)).must_equal(['sequel.execute'])
    end

    it 'traces direct executes' do
      memory_database.run('SELECT 1')

      _(exporter.finished_spans.size).must_equal 1
      _(exporter.finished_spans.map(&:name)).must_equal(['sequel.execute_dui'])
    end

    it 'traces model calls' do
      model.first

      _(exporter.finished_spans.size).must_equal 1
      _(exporter.finished_spans.map(&:name)).must_equal(['sequel.execute'])
    end

    it 'traces DUI calls' do
      memory_database.create_table(:test_table) { primary_key :id }

      _(exporter.finished_spans.size).must_equal 1
      _(exporter.finished_spans.map(&:name)).must_equal(['sequel.execute_dui'])
    end

    it 'traces INSERT calls' do
      memory_database[:documents].insert(title: 'insert')

      _(exporter.finished_spans.size).must_equal 1
      _(exporter.finished_spans.map(&:name)).must_equal(['sequel.execute_insert'])
    end

    it 'traces UPDATE calls' do
      memory_database[:documents].update(title: 'update')

      _(exporter.finished_spans.size).must_equal 1
      _(exporter.finished_spans.map(&:name)).must_equal(['sequel.execute_dui'])
    end

    it 'traces DELETE calls' do
      memory_database[:documents].delete

      _(exporter.finished_spans.size).must_equal 1
      _(exporter.finished_spans.map(&:name)).must_equal(['sequel.execute_dui'])
    end
  end

  describe 'recorded attributes' do
    it 'records the DB name and system' do
      file_database.run('SELECT 1')

      _(exporter.finished_spans.first.attributes).must_equal(
        'db.name' => db_file.path,
        'db.system' => 'sqlite'
      )
    end
  end
end
