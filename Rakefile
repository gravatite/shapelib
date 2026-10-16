# frozen_string_literal: true

require 'rubygems'
require 'rake'
require 'open3'
require 'tmpdir'
require 'rbconfig'
require 'shellwords'
require 'rake/clean'
require 'rake/testtask'
require 'rubygems/package_task'

desc 'Build and test every installed RVM Ruby, with a results table and logs'
task 'rvm-test' do
  root = __dir__
  env = ENV.keys.grep(/\ABUNDLE_/).to_h { |key| [key, nil] }
  env['RUBYOPT'] = nil
  env['RUBYLIB'] = nil

  begin
    output, error, status = Open3.capture3(env, 'rvm', 'list', 'strings')
  rescue Errno::ENOENT
    abort 'rvm-test: RVM is not installed or its executable is not on PATH.'
  end
  abort "rvm-test: unable to list installed Rubies: #{error.strip}" unless status.success?
  versions = output.lines.map(&:strip).reject(&:empty?).uniq.sort
  abort 'rvm-test: no installed RVM Rubies found.' if versions.empty?
  tests = Dir.glob(File.join(root, 'test/**/test_*.rb')).sort
  abort 'rvm-test: no test files found.' if tests.empty?

  logs = Dir.mktmpdir('shapelib-rvm-test-')
  results = []
  versions.each_with_index do |version, index|
    puts "Testing #{version} (#{index + 1}/#{versions.length})..."
    build_dir = File.join(logs, "build-#{index + 1}")
    Dir.mkdir(build_dir)
    run = lambda do |log, directory, *command|
      system(env, 'rvm', version, 'do', *command, chdir: directory, out: log, err: %i[child out])
    rescue SystemCallError => e
      log.puts e.message
      false
    end

    built = File.open(File.join(logs, "#{version}-build.log"), 'w') do |log|
      run.call(log, build_dir, 'ruby', File.join(root, 'ext/shapelib_ext/extconf.rb')) && run.call(log, build_dir, 'make')
    end
    passed = if built
               File.open(File.join(logs, "#{version}-test.log"), 'w') do |log|
                 run.call(log, root, 'ruby', "-I#{build_dir}", "-I#{File.join(root, 'lib')}", "-I#{File.join(root, 'test')}", '-e', 'ARGV.each { |file| require File.expand_path(file) }', *tests)
               end
             end
    results << [version, built ? 'PASS' : 'FAIL', if built
                                                    passed ? 'PASS' : 'FAIL'
                                                  else
                                                    'SKIPPED'
                                                  end]
  end

  width = [4, *versions.map(&:length)].max
  puts
  puts format("%-#{width}s  %-5s  %s", 'Ruby', 'Build', 'Tests')
  results.each { |row| puts format("%-#{width}s  %-5s  %s", *row) }
  puts "Logs and isolated builds: #{logs}"
  abort 'rvm-test: one or more versions failed; see the logs above.' if results.any? do |row|
    row[1..2] != %w[PASS PASS]
  end
end

spec = Gem::Specification.load(File.expand_path('shapelib.gemspec', __dir__))
abort 'Unable to load shapelib.gemspec' unless spec
Gem::PackageTask.new(spec) {}

desc 'Run tests, package the gem, and push it to RubyGems.org'
task release: %i[test gem] do
  sh Gem.ruby, '-S', 'gem', 'push', File.join('pkg', spec.file_name)
end

Rake::TestTask.new(:test) do |test|
  test.libs = %w[lib test]
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task test: :compile
task default: :test

build_dir = File.join('tmp', RUBY_PLATFORM, 'shapelib_ext', RUBY_VERSION)
extconf = File.expand_path('ext/shapelib_ext/extconf.rb', __dir__)
makefile = File.join(build_dir, 'Makefile')
binary = "shapelib_ext.#{RbConfig::CONFIG['DLEXT']}"

file makefile => [extconf] do
  mkdir_p build_dir
  Dir.chdir(build_dir) { sh Gem.ruby, extconf, *ARGV.grep(/\A--?/) }
end

desc 'Compile the extension for the current Ruby'
task compile: makefile do
  make = Shellwords.split(ENV['MAKE'] || RbConfig::CONFIG['MAKE'] || 'make')
  Dir.chdir(build_dir) { sh(*make) }
  cp File.join(build_dir, binary), File.join('lib', binary)
end
task 'compile:shapelib_ext' => :compile

CLEAN.include(build_dir)
CLOBBER.include('tmp', File.join('lib', binary))

rdoc_files = FileList['README*', 'lib/**/*.rb']
desc 'Build the HTML documentation'
task rdoc: 'rdoc/created.rid'
file 'rdoc/created.rid' => rdoc_files.to_a + ['Rakefile'] do
  begin
    require 'rdoc'
  rescue LoadError => error
    raise unless error.path == 'rdoc'

    abort 'Documentation requires RDoc. Install it with: gem install rdoc'
  end
  RDoc::RDoc.new.document(['--op', 'rdoc', '--title', 'shapelib', *rdoc_files])
end

desc 'Rebuild the HTML documentation from scratch'
task rerdoc: %i[clobber_rdoc rdoc]
desc 'Remove generated HTML documentation'
task :clobber_rdoc do
  rm_rf 'rdoc'
end
task clobber: :clobber_rdoc
