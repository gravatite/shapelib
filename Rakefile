require 'rubygems'
require 'rake'
require 'jeweler'
$LOAD_PATH << File.expand_path('lib')

begin
  require 'shapelib/version'
  Jeweler::Tasks.new do |gem|
    gem.name = "shapelib"
    gem.summary = %Q{Simple wrapper around the shapelib library}
    gem.description = gem.summary
    gem.email = %q{mmangino@elevatedrails.com}
    gem.homepage = "http://github.com/mperham/shapelib"
    gem.authors =  ["prasinos@users.sourceforge.net", "Mike Mangino", "Mike Perham"]
    gem.add_development_dependency 'rake-compiler', '>= 0.7.0'
    gem.has_rdoc = false
    gem.version = Shapelib::VERSION
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError => le
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler: #{le.message}"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs = %w(lib test)
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :test => :check_dependencies
task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "shapelib"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


gem 'rake-compiler', '>= 0.7.0'
require "rake/extensiontask"

Rake::ExtensionTask.new('shapelib_ext')
