# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'yaml'

task default: %i[test rubocop]

begin
  fork { nil }
rescue NotImplementedError
  # jruby, truffleruby, and windows can't fork so use vanilla rake instead
  warn 'warn: fork is not implemented on this Ruby, falling back to vanilla rake'
  require 'rake/testtask'
  Rake::TestTask.new do |t|
    t.libs << 'test'
    t.test_files = FileList['test/test_*.rb']
    t.verbose = true
  end
else
  desc 'Run each test in isolation'
  task :test do
    sh 'forking-test-runner test/test_* --helper test/helper.rb --verbose'
  end
end

RuboCop::RakeTask.new
