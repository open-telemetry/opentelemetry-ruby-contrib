require 'digest'

digest = Digest::MD5.new
digest.update('test')
digest.update(ENV.fetch('BUNDLE_GEMFILE', 'gemfile')) if ENV['APPRAISAL_INITIALIZED']

ENV['ENABLE_COVERAGE'] ||= '1'

if ENV['ENABLE_COVERAGE'].to_i.positive?
  SimpleCov.command_name(digest.hexdigest)
  SimpleCov.start do
    add_filter %r{^/test/}
  end
end
