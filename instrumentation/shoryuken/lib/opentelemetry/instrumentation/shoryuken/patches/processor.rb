# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module Shoryuken
      module Patches
        # The Processor module silences the instrumentation for the process method
        module Processor
          def process
            OpenTelemetry::Common::Utilities.untraced { super }
          end
        end
      end
    end
  end
end
