# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module OpenAI
      module Patches
        # Determine the operation name from the request path
        module OperationName
          def determine_operation_name(req)
            path = req[:path].to_s

            case path
            when %r{^chat/completions}
              'chat'
            when /^embeddings/
              'embeddings'
            when /^completions/
              'completions'
            when %r{^images/generations}
              'images.generate'
            when %r{^images/edits}
              'images.edit'
            when %r{^images/variations}
              'images.variation'
            when %r{^audio/transcriptions}
              'audio.transcription'
            when %r{^audio/translations}
              'audio.translation'
            when %r{^audio/speech}
              'audio.speech'
            when /^models/
              'models'
            when /^files/
              'files'
            when %r{^fine_tuning/jobs}
              'fine_tuning.jobs'
            when %r{^fine_tuning/alpha/graders/run}
              'fine_tuning.graders.run'
            when %r{^fine_tuning/alpha/graders/validate}
              'fine_tuning.graders.validate'
            when /^fine_tuning/
              'fine_tuning'
            when /^moderations/
              'moderations'
            when /^batches/
              'batches'
            when /^uploads/
              'uploads'
            when /^vector_stores/
              'vector_stores'
            when /^assistants/
              'assistants'
            when %r{^threads/runs}
              'threads.runs'
            when /^threads/
              'threads'
            when /^conversations/
              'conversations'
            when %r{^responses/input_tokens}
              'responses.input_tokens'
            when /^responses/
              'responses'
            when /^containers/
              'containers'
            when /^evals/
              'evals'
            when /^videos/
              'videos'
            when %r{^chatkit/sessions}
              'chatkit.sessions'
            when %r{^chatkit/threads}
              'chatkit.threads'
            when %r{^realtime/client_secrets}
              'realtime.client_secrets'
            else
              'openai.request'
            end
          end
        end
      end
    end
  end
end
