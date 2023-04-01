require "bundler"
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  raise LoadError.new("Unable to setup Bundler; you might need to `bundle install`: #{e.message}")
end

require "rspec/core/rake_task"
require "rake/clean"
require "fileutils"

CLEAN.include %w[build_test_run .yardoc yard coverage test]

RSpec::Core::RakeTask.new(:spec, :example_string) do |task, args|
  if args.example_string
    task.rspec_opts = %W[-e "#{args.example_string}" -f documentation]
  end
end

task default: :spec
