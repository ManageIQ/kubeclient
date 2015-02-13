require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

task default: [:test, :rubocop]

task :test do
  Dir.glob('./test/*_test.rb').each { |file| require file }
end

RuboCop::RakeTask.new
