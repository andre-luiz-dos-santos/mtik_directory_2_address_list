require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc 'Run tests with simplecov enabled'
task :coverage do
  ENV['COVERAGE'] = 'yes'
  Rake::Task['test'].execute
end

desc 'Run tests'
task :default => [:test]
