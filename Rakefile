# frozen_string_literal: true

require 'rubygems'
require 'rake'
require 'open3'
require 'tmpdir'

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

unless Rake.application.top_level_tasks == ['rvm-test']
  require 'rubygems/package_task'
  spec = Gem::Specification.load(File.expand_path('shapelib.gemspec', __dir__))
  abort 'Unable to load shapelib.gemspec' unless spec
  Gem::PackageTask.new(spec) {}

  desc 'Run tests, package the gem, and push it to RubyGems.org'
  task release: %i[test gem] do
    sh Gem.ruby, '-S', 'gem', 'push', File.join('pkg', spec.file_name)
  end

  require 'rake/testtask'
  Rake::TestTask.new(:test) do |test|
    test.libs = %w[lib test]
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end

  task test: :compile
  task default: :test

  require 'rdoc/task'
  Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = 'shapelib'
    rdoc.rdoc_files.include('README*')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end

  gem 'rake-compiler', '>= 0.7.0'
  require 'rake/extensiontask'

  Rake::ExtensionTask.new('shapelib_ext')
end
