#!/usr/bin/ruby
require 'mkmf'

HEADER_DIRS = [
  '/opt/local/include',
  '/usr/local/include',
  '/usr/include',
]

LIB_DIRS = [
  '/opt/local/lib',
  '/usr/local/lib',
  '/usr/lib',
]

dir_config('shapelib', HEADER_DIRS, LIB_DIRS)
have_header('shapefil.h') or have_header('libshp/shapefil.h') or raise 'shapefil.h not found'
have_library('shp') or raise 'libshp not found'
create_makefile('shapelib_ext')
