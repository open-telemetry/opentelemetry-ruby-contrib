module OpenTelemetry
  module Instrumentation
    module RubyKafka
      module Patches
        # The AsyncProducer module contains the instrumentation patch the AsyncProducer#produce method
        module AsyncProducer
          def produce(value, topic:, **options)
            # The propagator mutates the carrier, so we need to set to empty hash so that it's not nil
            options[:headers] = {} unless options[:headers]
            OpenTelemetry.propagation.inject(options[:headers])
            super
          end
        end
      end
    end
  end
end
