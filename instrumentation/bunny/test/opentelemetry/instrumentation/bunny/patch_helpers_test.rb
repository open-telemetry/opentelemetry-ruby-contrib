# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../lib/opentelemetry/instrumentation/bunny/patch_helpers'

describe OpenTelemetry::Instrumentation::Bunny::PatchHelpers do
  let(:properties) do
    {
      headers: {
        'traceparent' => '00-eab67ae26433f603121bd5674149d9e1-2007f3325d3cb6d6-01'
      },
      tracer_receive_headers: {
        'traceparent' => '00-cd52775b3cb38931adf5fa880f890c25-cddb52a470027489-01'
      }
    }
  end

  describe '.extract_context' do
    it 'returns the parent context with links when headers from producer exists' do
      parent_context, links = OpenTelemetry::Instrumentation::Bunny::PatchHelpers.extract_context(properties)
      _(parent_context).must_be_instance_of(OpenTelemetry::Context)
      _(links).must_be_instance_of(Array)
      _(links.first).must_be_instance_of(OpenTelemetry::Trace::Link)
    end

    it 'returns the parent context with no links when headers from producer not present' do
      properties.delete(:headers)
      parent_context, links = OpenTelemetry::Instrumentation::Bunny::PatchHelpers.extract_context(properties)
      _(parent_context).must_be_instance_of(OpenTelemetry::Context)
      _(links).must_be_nil
    end
  end
end
