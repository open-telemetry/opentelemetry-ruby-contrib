# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../../lib/opentelemetry/instrumentation/openai/patches/operation_name'

describe OpenTelemetry::Instrumentation::OpenAI::Patches::OperationName do
  let(:operation_name_module) do
    Class.new do
      include OpenTelemetry::Instrumentation::OpenAI::Patches::OperationName
    end.new
  end

  describe '#determine_operation_name' do
    it 'returns chat for chat completions path' do
      req = { path: 'chat/completions' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'chat'
    end

    it 'returns embeddings for embeddings path' do
      req = { path: 'embeddings' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'embeddings'
    end

    it 'returns completions for completions path' do
      req = { path: 'completions' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'completions'
    end

    it 'returns images.generate for images generations path' do
      req = { path: 'images/generations' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'images.generate'
    end

    it 'returns images.edit for images edits path' do
      req = { path: 'images/edits' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'images.edit'
    end

    it 'returns images.variation for images variations path' do
      req = { path: 'images/variations' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'images.variation'
    end

    it 'returns audio.transcription for audio transcriptions path' do
      req = { path: 'audio/transcriptions' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'audio.transcription'
    end

    it 'returns audio.translation for audio translations path' do
      req = { path: 'audio/translations' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'audio.translation'
    end

    it 'returns audio.speech for audio speech path' do
      req = { path: 'audio/speech' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'audio.speech'
    end

    it 'returns models for models path' do
      req = { path: 'models' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'models'
    end

    it 'returns files for files path' do
      req = { path: 'files' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'files'
    end

    it 'returns fine_tuning.jobs for fine tuning jobs path' do
      req = { path: 'fine_tuning/jobs' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'fine_tuning.jobs'
    end

    it 'returns fine_tuning.graders.run for fine tuning graders run path' do
      req = { path: 'fine_tuning/alpha/graders/run' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'fine_tuning.graders.run'
    end

    it 'returns fine_tuning.graders.validate for fine tuning graders validate path' do
      req = { path: 'fine_tuning/alpha/graders/validate' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'fine_tuning.graders.validate'
    end

    it 'returns fine_tuning for generic fine tuning path' do
      req = { path: 'fine_tuning' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'fine_tuning'
    end

    it 'returns moderations for moderations path' do
      req = { path: 'moderations' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'moderations'
    end

    it 'returns batches for batches path' do
      req = { path: 'batches' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'batches'
    end

    it 'returns uploads for uploads path' do
      req = { path: 'uploads' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'uploads'
    end

    it 'returns vector_stores for vector stores path' do
      req = { path: 'vector_stores' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'vector_stores'
    end

    it 'returns assistants for assistants path' do
      req = { path: 'assistants' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'assistants'
    end

    it 'returns threads.runs for threads runs path' do
      req = { path: 'threads/runs' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'threads.runs'
    end

    it 'returns threads for threads path' do
      req = { path: 'threads' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'threads'
    end

    it 'returns conversations for conversations path' do
      req = { path: 'conversations' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'conversations'
    end

    it 'returns responses.input_tokens for responses input tokens path' do
      req = { path: 'responses/input_tokens' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'responses.input_tokens'
    end

    it 'returns responses for responses path' do
      req = { path: 'responses' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'responses'
    end

    it 'returns containers for containers path' do
      req = { path: 'containers' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'containers'
    end

    it 'returns evals for evals path' do
      req = { path: 'evals' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'evals'
    end

    it 'returns videos for videos path' do
      req = { path: 'videos' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'videos'
    end

    it 'returns chatkit.sessions for chatkit sessions path' do
      req = { path: 'chatkit/sessions' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'chatkit.sessions'
    end

    it 'returns chatkit.threads for chatkit threads path' do
      req = { path: 'chatkit/threads' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'chatkit.threads'
    end

    it 'returns realtime.client_secrets for realtime client secrets path' do
      req = { path: 'realtime/client_secrets' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'realtime.client_secrets'
    end

    it 'returns openai.request for unknown path' do
      req = { path: 'unknown/endpoint' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'openai.request'
    end

    it 'handles nil path gracefully' do
      req = { path: nil }
      _(operation_name_module.determine_operation_name(req)).must_equal 'openai.request'
    end

    it 'handles path as symbol' do
      req = { path: :'chat/completions' }
      _(operation_name_module.determine_operation_name(req)).must_equal 'chat'
    end
  end
end
