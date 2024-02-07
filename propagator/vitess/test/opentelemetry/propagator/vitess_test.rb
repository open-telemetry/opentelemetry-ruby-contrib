# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::Propagator::Vitess do
  describe '#sql_query_propagator' do
    it 'returns an instance of SqlQueryPropagator' do
      propagator = OpenTelemetry::Propagator::Vitess.sql_query_propagator
      _(propagator).must_be_instance_of(
        OpenTelemetry::Propagator::Vitess::SqlQueryPropagator
      )
    end
  end
end
