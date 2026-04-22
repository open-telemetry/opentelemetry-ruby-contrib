# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'net/ldap'

Bundler.require

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Net::LDAP'
end

ldap = Net::LDAP.new  host: 'your_ldap_host',
                      port: 'your_ldap_port',
                      encryption: :simple_tls,
                      base: 'base',
                      auth: {
                        method: :simple,
                        username: 'username',
                        password: 'password'
                      }
ldap.open do |ldap|
  ldap.search(args)
  ldap.add(args)
  ldap.modify(args)
end
