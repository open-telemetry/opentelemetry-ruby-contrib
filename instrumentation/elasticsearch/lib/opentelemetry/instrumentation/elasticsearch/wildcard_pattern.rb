# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Elasticsearch
      # Object representing a user-supplied key pattern that behaves as a regex
      class WildcardPattern
        def initialize(str)
          @pattern = convert(str)
        end

        attr_reader :pattern

        def match?(other)
          !!@pattern.match(other)
        end

        alias match match?

        private

        def convert(str)
          case_sensitive = false

          if str.start_with?('(?-i)')
            str = str.gsub(/^\(\?-\i\)/, '')
            case_sensitive = true
          end

          parts =
            str.chars.each_with_object([]) do |char, arr|
              arr << (char == '*' ? '.*' : Regexp.escape(char))
            end

          Regexp.new(
            '\A' + parts.join + '\Z', # rubocop:disable Style/StringConcatenation
            case_sensitive ? nil : Regexp::IGNORECASE
          )
        end
      end
    end
  end
end
