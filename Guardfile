require_relative 'spec/support/integration_specs'

run_all = lambda do |*|
  Compat::UI.info('Running all integration tests', reset: true)
  run_all_integration_specs(logger: ->(msg) { Compat::UI.info(msg) })
end

guard 'rspec', all_on_start: false, cmd: 'bundle exec rspec', run_all: { cmd: 'bundle exec rspec --exclude-pattern "spec/integration/**/*_spec.rb"' } do
  watch(%r{^spec(?!/integration)/.+_spec\.rb})
  watch(%r{^lib/(.+)\.rb}) { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { 'spec' }
end

guard :yield, run_all: run_all do
  watch(%r{^lib/(.+)\.rb}) { run_all.call }
  watch(%r{^spec/integration/(?<integration>.*)/.+_spec\.rb}) do |file, integration|
    Compat::UI.info(%(Running "#{integration}" integration test), reset: true)
    system(integration_command(integration, 'bundle --quiet'))
    system(integration_command(integration, "bundle exec rspec #{file}"))
  end
end
