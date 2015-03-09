require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

task default: [:test, :rubocop]

Rake::TestTask.new do |t|
  t.libs << 'test'
end

RuboCop::RakeTask.new
