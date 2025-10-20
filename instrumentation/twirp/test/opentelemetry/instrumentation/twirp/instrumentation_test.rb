# # frozen_string_literal: true
#
# # Copyright The OpenTelemetry Authors
# #
# # SPDX-License-Identifier: Apache-2.0
#
# require 'test_helper'
#
# require_relative '../../../../lib/opentelemetry/instrumentation/twirp'
# require_relative '../../../support/fake_services'
#
# describe OpenTelemetry::Instrumentation::Twirp do
#   let(:instrumentation) { OpenTelemetry::Instrumentation::Twirp::Instrumentation.instance }
#   let(:exporter) { EXPORTER }
#   let(:spans) { exporter.finished_spans }
#
#   before do
#     exporter.reset
#
#     instrumentation.install
#   end
#
#   it 'has #name' do
#     _(instrumentation.name).must_equal 'OpenTelemetry::Instrumentation::Twirp'
#   end
#
#   it 'has #version' do
#     _(instrumentation.version).wont_be_nil
#     _(instrumentation.version).wont_be_empty
#   end
#
#   describe '#install' do
#     it 'accepts argument' do
#       _(instrumentation.install({})).must_equal(true)
#       instrumentation.instance_variable_set(:@installed, false)
#     end
#
#     it 'accepts peer_service option' do
#       instrumentation.instance_variable_set(:@config, peer_service: 'test-service')
#       _(instrumentation.config[:peer_service]).must_equal 'test-service'
#     end
#
#     it 'accepts install_rack option' do
#       instrumentation.instance_variable_set(:@config, install_rack: true)
#       _(instrumentation.config[:install_rack]).must_equal true
#     end
#   end
# end
