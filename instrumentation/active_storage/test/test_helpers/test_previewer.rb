# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# TestPreviewer does not require dependencies like MuPDF and Poppler, so when testing, you can replace
# config.active_storage.previewers with this class to test the preview hook with minimal dependencies.
class TestPreviewer < ActiveStorage::Previewer
  def self.accept?(blob)
    blob.content_type.start_with?('application/pdf')
  end

  def preview(**options)
    download_blob_to_tempfile do |input|
      draw_sample_image input do |_output|
        file = File.open("#{Dir.pwd}/test/fixtures/sample.png")
        yield io: file, filename: 'sample.png', content_type: 'image/png', **options
      end
    end
  end

  private

  def draw_sample_image(file, &)
    draw('echo', '"test previewer called"', &)
  end
end
