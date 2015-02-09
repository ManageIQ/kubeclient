require 'bundler/gem_tasks'
require 'rake/testtask'

task default: :test
task :test do
  Dir.glob('./test/*_test.rb').each { |file| require file }
end
