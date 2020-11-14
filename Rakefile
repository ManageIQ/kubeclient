require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'yaml'

task default: %i[test rubocop] # same as .github/workflows/actions.yml

Rake::TestTask.new
RuboCop::RakeTask.new
