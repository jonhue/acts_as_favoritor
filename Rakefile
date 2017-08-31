require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rake/testtask'
require 'rdoc/task'

desc 'Default: run unit tests.'
task default: :test

desc 'Test the acts_as_favoritor gem.'
Rake::TestTask.new(:test) do |t|
    t.libs << 'lib'
    t.pattern = 'test/**/*_test.rb'
    t.verbose = true
end
