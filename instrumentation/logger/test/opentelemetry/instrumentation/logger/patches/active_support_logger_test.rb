# frozen_string_literal: true

# # Copyright The OpenTelemetry Authors
# #
# # SPDX-License-Identifier: Apache-2.0

# require 'test_helper'

# require_relative '../../../../../lib/opentelemetry/instrumentation/logger/patches/active_support_logger'

# describe OpenTelemetry::Instrumentation::Logger::Patches::ActiveSupportLogger do
#   let(:instrumentation) { OpenTelemetry::Instrumentation::Logger::Instrumentation.instance }
#   let(:exporter) { EXPORTER }
#   let(:log_record) { exporter.emitted_log_records.first }
#   let(:rails_logger) { Rails.logger }
#   let(:log_stream) { LOG_STREAM }
#   # let(:ruby_logger) { Logger.new(log_stream) }
#   let(:msg) { 'message' }

#   before do
#     exporter.reset
#     instrumentation.install
#   end

#   after { instrumentation.instance_variable_set(:@installed, false) }

#   describe '#broadcast' do
#     it 'adds @skip_instrumenting to broadcasted loggers' do
#       rails_logger.debug(msg)
#       assert_match(/DEBUG -- : #{msg}/, log_stream.string)
#     end

#     it 'does not add @skip_instrumenting to the initial logger' do

#     end
#   end
# end
