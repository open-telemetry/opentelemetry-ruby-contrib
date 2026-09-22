# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

require_relative '../../../../lib/opentelemetry/instrumentation/grape'
require_relative '../../../../lib/opentelemetry/instrumentation/grape/event_handler'
require_relative '../../../../lib/opentelemetry/instrumentation/grape/v3/event_handler'
require_relative '../../../../lib/opentelemetry/instrumentation/grape/v4/event_handler'

describe OpenTelemetry::Instrumentation::Grape::V3::EventHandler do
  let(:handler) { OpenTelemetry::Instrumentation::Grape::V3::EventHandler }

  describe '#request_method' do
    it 'returns method from endpoint options when options is a Hash' do
      endpoint = Struct.new(:options).new({ method: ['GET'] })
      _(handler.send(:request_method, endpoint)).must_equal 'GET'
    end

    it 'falls back to route request_method when options is not a Hash' do
      route = Struct.new(:request_method).new('POST')
      endpoint = Struct.new(:options, :routes).new(nil, [route])
      _(handler.send(:request_method, endpoint)).must_equal 'POST'
    end

    it 'returns nil when request method cannot be determined' do
      endpoint = Struct.new(:options, :routes).new(nil, nil)
      _(handler.send(:request_method, endpoint)).must_be_nil
    end
  end

  describe '#code_namespace' do
    it 'returns owner name from endpoint options when options is a Hash' do
      api_class = Class.new do
        def self.name
          'MyAPI'
        end
      end
      endpoint = Struct.new(:options).new({ for: api_class })
      _(handler.send(:code_namespace, endpoint)).must_equal 'MyAPI'
    end

    it 'falls back to endpoint api reader' do
      api_class = Class.new do
        def self.name
          'MyAPI'
        end
      end
      endpoint = Struct.new(:options, :api).new(nil, api_class)
      _(handler.send(:code_namespace, endpoint)).must_equal 'MyAPI'
    end

    it 'uses base when owner name is nil' do
      base_class = Class.new do
        def self.to_s
          'BaseAPI'
        end
      end
      owner = Class.new
      owner.instance_variable_set(:@base, base_class)
      endpoint = Struct.new(:options, :api).new(nil, owner)
      _(handler.send(:code_namespace, endpoint)).must_equal 'BaseAPI'
    end

    it 'returns nil when no owner is resolved' do
      endpoint = Struct.new(:options).new(nil)
      _(handler.send(:code_namespace, endpoint)).must_be_nil
    end
  end

  describe '#raw_endpoint_path' do
    it 'returns path array from options hash' do
      endpoint = Struct.new(:options).new({ path: ['users', ':id'] })
      _(handler.send(:raw_endpoint_path, endpoint)).must_equal ['users', ':id']
    end

    it 'returns nil when path is absent' do
      endpoint = Struct.new(:options).new(nil)
      _(handler.send(:raw_endpoint_path, endpoint)).must_be_nil
    end
  end

  describe '#route_namespace' do
    it 'returns route namespace when present' do
      route = Struct.new(:namespace).new('v1/users')
      _(handler.send(:route_namespace, route)).must_equal 'v1/users'
    end

    it 'falls back to route options namespace' do
      route = Struct.new(:options).new({ namespace: 'v2/admin' })
      _(handler.send(:route_namespace, route)).must_equal 'v2/admin'
    end

    it 'returns nil when namespace is not present' do
      route = Struct.new(:options).new({})
      _(handler.send(:route_namespace, route)).must_be_nil
    end
  end

  describe '#route_version' do
    it 'returns route version string' do
      route = Struct.new(:version).new('v1')
      _(handler.send(:route_version, route)).must_equal 'v1'
    end

    it 'handles array route version' do
      route = Struct.new(:version).new(['v2'])
      _(handler.send(:route_version, route)).must_equal 'v2'
    end

    it 'falls back to route options version' do
      route = Struct.new(:options).new({ version: 'v3' })
      _(handler.send(:route_version, route)).must_equal 'v3'
    end

    it 'returns nil when version is not present' do
      route = Struct.new(:options).new({})
      _(handler.send(:route_version, route)).must_be_nil
    end
  end

  describe '#route_prefix' do
    it 'returns route prefix string' do
      route = Struct.new(:prefix).new('api')
      _(handler.send(:route_prefix, route)).must_equal 'api'
    end

    it 'converts symbol route prefix to string' do
      route = Struct.new(:prefix).new(:api)
      _(handler.send(:route_prefix, route)).must_equal 'api'
    end

    it 'falls back to route options prefix' do
      route = Struct.new(:options).new({ prefix: 'api' })
      _(handler.send(:route_prefix, route)).must_equal 'api'
    end

    it 'returns nil when prefix is not present' do
      route = Struct.new(:options).new({})
      _(handler.send(:route_prefix, route)).must_be_nil
    end
  end
end

describe OpenTelemetry::Instrumentation::Grape::V4::EventHandler do
  let(:handler) { OpenTelemetry::Instrumentation::Grape::V4::EventHandler }

  describe '#request_method' do
    it 'returns method from config http_methods' do
      config = Struct.new(:http_methods).new(['PUT'])
      endpoint_class = Class.new do
        def initialize(config)
          @config = config
        end

        def routes
          nil
        end
      end
      endpoint = endpoint_class.new(config)
      _(handler.send(:request_method, endpoint)).must_equal 'PUT'
    end

    it 'falls back to route request_method when config does not provide method' do
      route = Struct.new(:request_method).new('PATCH')
      endpoint = Struct.new(:routes).new([route])
      _(handler.send(:request_method, endpoint)).must_equal 'PATCH'
    end

    it 'returns nil when request method cannot be determined' do
      endpoint = Struct.new(:routes).new(nil)
      _(handler.send(:request_method, endpoint)).must_be_nil
    end
  end

  describe '#code_namespace' do
    it 'returns owner from config api reader' do
      api_class = Class.new do
        def self.name
          'ConfigAPI'
        end
      end
      config = Struct.new(:api).new(api_class)
      endpoint_class = Class.new do
        def initialize(config)
          @config = config
        end
      end
      endpoint = endpoint_class.new(config)
      _(handler.send(:code_namespace, endpoint)).must_equal 'ConfigAPI'
    end

    it 'returns owner from config for reader' do
      api_class = Class.new do
        def self.name
          'ForAPI'
        end
      end
      config = Struct.new(:for).new(api_class)
      endpoint_class = Class.new do
        def initialize(config)
          @config = config
        end
      end
      endpoint = endpoint_class.new(config)
      _(handler.send(:code_namespace, endpoint)).must_equal 'ForAPI'
    end

    it 'returns nil when no owner is resolved' do
      endpoint = Class.new.new
      _(handler.send(:code_namespace, endpoint)).must_be_nil
    end
  end

  describe '#raw_endpoint_path' do
    it 'returns path array from config path' do
      config = Struct.new(:path).new(['items'])
      endpoint_class = Class.new do
        def initialize(config)
          @config = config
        end
      end
      endpoint = endpoint_class.new(config)
      _(handler.send(:raw_endpoint_path, endpoint)).must_equal ['items']
    end

    it 'returns nil when config is absent' do
      endpoint = Class.new.new
      _(handler.send(:raw_endpoint_path, endpoint)).must_be_nil
    end
  end

  describe '#route_namespace' do
    it 'returns route namespace when present' do
      route = Struct.new(:namespace).new('v4/users')
      _(handler.send(:route_namespace, route)).must_equal 'v4/users'
    end

    it 'returns nil when route does not have namespace' do
      route = Class.new.new
      _(handler.send(:route_namespace, route)).must_be_nil
    end
  end

  describe '#route_version' do
    it 'returns route version string' do
      route = Struct.new(:version).new('v4')
      _(handler.send(:route_version, route)).must_equal 'v4'
    end

    it 'handles array route version' do
      route = Struct.new(:version).new(['v4'])
      _(handler.send(:route_version, route)).must_equal 'v4'
    end

    it 'returns nil when version is not present' do
      route = Class.new.new
      _(handler.send(:route_version, route)).must_be_nil
    end
  end

  describe '#route_prefix' do
    it 'returns route prefix string' do
      route = Struct.new(:prefix).new('api')
      _(handler.send(:route_prefix, route)).must_equal 'api'
    end

    it 'returns nil when prefix is not present' do
      route = Class.new.new
      _(handler.send(:route_prefix, route)).must_be_nil
    end
  end
end

describe OpenTelemetry::Instrumentation::Grape::EventHandler do
  let(:handler) { OpenTelemetry::Instrumentation::Grape::EventHandler }

  describe '#fallback_path_from_route' do
    it 'strips format suffix from route origin' do
      route = Struct.new(:origin, :version).new('/api/users(.:format)', nil)
      _(handler.send(:fallback_path_from_route, route)).must_equal '/api/users'
    end

    it 'substitutes version placeholder in origin' do
      route = Struct.new(:origin, :version).new('/:version/users(.:format)', 'v1')
      _(handler.send(:fallback_path_from_route, route)).must_equal '/v1/users'
    end

    it 'adds leading slash if missing' do
      route = Struct.new(:origin, :version).new('hello', nil)
      _(handler.send(:fallback_path_from_route, route)).must_equal '/hello'
    end

    it 'falls back to route path when origin is absent' do
      route = Struct.new(:origin, :path, :version).new(nil, '/orders/:id(.:format)', nil)
      _(handler.send(:fallback_path_from_route, route)).must_equal '/orders/:id'
    end

    it 'returns empty string when neither origin nor path is available' do
      route = Struct.new(:version).new(nil)
      _(handler.send(:fallback_path_from_route, route)).must_equal ''
    end
  end

  describe '#path' do
    it 'returns empty string when endpoint routes is nil or empty' do
      endpoint_nil = Struct.new(:routes).new(nil)
      _(handler.send(:path, endpoint_nil)).must_equal ''

      endpoint_empty = Struct.new(:routes).new([])
      _(handler.send(:path, endpoint_empty)).must_equal ''
    end

    it 'constructs path when raw_endpoint_path is available' do
      route = Struct.new(:namespace, :version, :prefix).new('users', 'v1', 'api')
      endpoint = Struct.new(:routes, :options).new([route], { path: [':id'] })
      _(handler.send(:path, endpoint)).must_equal '/api/v1/users/:id'
    end

    it 'falls back to route origin when raw_endpoint_path is absent' do
      route = Struct.new(:origin, :version).new('/api/v2/items/:item_id(.:format)', nil)
      endpoint = Struct.new(:routes, :options).new([route], nil)
      _(handler.send(:path, endpoint)).must_equal '/api/v2/items/:item_id'
    end
  end
end
