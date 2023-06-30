module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Patches
        # The AsyncProducer module contains the instrumentation patch the AsyncProducer#produce method
        module AsyncProducer
          def produce(value, topic:, **options)
            options = { headers: {} } unless options
            # The propagator mutates the carrier (first positional argument), so we need to set headers to empty hash so
            # that there's something to mutate
            options[:headers] = {} unless options[:headers]
            OpenTelemetry.propagation.inject(options[:headers])
            super
          end
        end
      end
    end
  end
end
