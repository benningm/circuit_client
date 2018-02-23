require 'rake/clean'
require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'                                                                       

spec = eval(File.read('circuit_client.gemspec'))
Gem::PackageTask.new(spec) do |pkg|
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include("lib/**/*.rb","bin/**/*")
  rd.title = 'Circuit Client for REST API'
end                                                                                       

