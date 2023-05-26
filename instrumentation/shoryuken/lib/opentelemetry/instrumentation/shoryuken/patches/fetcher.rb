# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module Shoryuken
      module Patches
        # The Fetcher module silences the instrumentation for the fetch method
        module Fetcher
          def fetch(queue, limit)
            OpenTelemetry::Common::Utilities.untraced { super }
          end
        end
      end
    end
  end
end
