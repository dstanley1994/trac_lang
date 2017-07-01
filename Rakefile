require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rdoc/task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

RDoc::Task.new do |rdoc|
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_dir = 'doc'
end