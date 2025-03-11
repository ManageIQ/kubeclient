# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'yaml'

task default: %i[test rubocop]

begin
  fork { nil }
rescue NotImplementedError
  # jruby and windows can't fork so use vanilla rake instead
  require 'rake/testtask'
else
  desc 'Run each test in isolation'
  task :test do
    sh 'forking-test-runner test/test_* --helper test/helper.rb --verbose'
  end
end
RuboCop::RakeTask.new
