# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

url = URI.parse('http://catfact.ninja/fact')
req = Net::HTTP::Get.new(url.to_s)
Net::HTTP.start(url.host, url.port) do |http|
  http.request(req)
end
