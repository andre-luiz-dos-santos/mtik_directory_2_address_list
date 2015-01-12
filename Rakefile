require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

task :coverage do
  ENV['COVERAGE'] = 'yes'
  Rake::Task['test'].execute
end

desc 'Run tests and build gem'
task :default => [:test]
