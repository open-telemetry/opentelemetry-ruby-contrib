# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Sampling
    module XRay
      class Matcher
        SINGLE_CHAR_WILD_CARD = '?'
        ZERO_OR_MORE_CHAR_WILD_CARD = '*'

        # @param [String] input
        # @return [Boolean]
        def match?(input)
          raise(NotImplementedError, 'Subclasses must implement match?')
        end

        # @param [String] glob_pattern
        # @return [Matcher]
        def self.to_matcher(glob_pattern)
          if glob_pattern == ZERO_OR_MORE_CHAR_WILD_CARD
            TrueMatcher.new
          elsif glob_pattern.include?(SINGLE_CHAR_WILD_CARD) || glob_pattern.include?(ZERO_OR_MORE_CHAR_WILD_CARD)
            PatternMatcher.new(glob_pattern)
          else
            StringMatcher.new(glob_pattern)
          end
        end
      end

      class TrueMatcher < Matcher
        # @param [String] input
        # @return [Boolean]
        def match?(input)
          true
        end
      end

      class StringMatcher < Matcher
        # @param [String] target
        def initialize(target)
          @target = target
        end

        # @param [String] input
        # @return [Boolean]
        def match?(input)
          input == @target
        end
      end

      class PatternMatcher < Matcher
        # @param [String] glob_pattern
        def initialize(glob_pattern)
          @pattern = Regexp.quote(glob_pattern).gsub("\\#{ZERO_OR_MORE_CHAR_WILD_CARD}", '.*').gsub("\\#{SINGLE_CHAR_WILD_CARD}", '.')
        end

        # @param [String] input
        # @return [Boolean]
        def match?(input)
          !input.nil? && input.match?(@pattern)
        end
      end
    end
  end
end
