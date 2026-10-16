# frozen_string_literal: true

require_relative 'lib/shapelib/version'

Gem::Specification.new do |s|
  s.name = 'shapelib'
  s.version = Shapelib::VERSION
  s.required_ruby_version = '>= 2.6'
  s.licenses = ['MIT', 'LGPL-2.0-only', 'CC-BY-SA-3.0']

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.require_paths = ['lib']
  s.authors = ['prasinos@users.sourceforge.net', 'Mike Mangino', 'Mike Perham', 'Nick Estes']
  s.description = 'Simple wrapper around the shapelib library'
  s.email = 'nick@nickstoys.com'
  s.extensions = ['ext/shapelib_ext/extconf.rb']
  s.extra_rdoc_files = [
    'README.md'
  ]
  s.files = [
    'LICENSE',
    'LICENSE-MIT',
    'LICENSE-LGPL',
    'LICENSE-CC-BY-SA-3.0',
    'README.md',
    'Rakefile',
    'doc/Interface.html',
    'doc/Interface.rd',
    'doc/style.css',
    'ext/shapelib_ext/depend',
    'ext/shapelib_ext/extconf.rb',
    'ext/shapelib_ext/main.c',
    'ext/shapelib_ext/sfcode.h',
    'ext/shapelib_ext/sflist.h',
    'ext/shapelib_ext/shpplus.c',
    'ext/shapelib_ext/shpplus.h',
    'ext/shapelib_ext/spcode.h',
    'ext/shapelib_ext/splist.h',
    'ext/shapelib_ext/spwkt.h',
    'ext/shapelib_ext/valconv.h',
    'lib/shapelib.rb',
    'lib/shapelib/shape.rb',
    'lib/shapelib/version.rb',
    'shapelib.gemspec',
    'test/data/ZillowNeighborhoods-CA/ZillowNeighborhoods-CA.dbf',
    'test/data/ZillowNeighborhoods-CA/ZillowNeighborhoods-CA.prj',
    'test/data/ZillowNeighborhoods-CA/ZillowNeighborhoods-CA.shp',
    'test/data/ZillowNeighborhoods-CA/ZillowNeighborhoods-CA.shp.xml',
    'test/data/ZillowNeighborhoods-CA/ZillowNeighborhoods-CA.shx',
    'test/test_zillow_data.rb'
  ]
  s.homepage = 'http://github.com/mperham/shapelib'
  s.summary = 'Simple wrapper around the shapelib library'

  s.add_development_dependency 'rake', '>= 13.0'
  s.add_development_dependency 'test-unit', '>= 3.0'
  s.metadata['rubygems_mfa_required'] = 'true'
end
