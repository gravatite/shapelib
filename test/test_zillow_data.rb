require 'shapelib'
require 'test/unit'
require 'tmpdir'
require 'fileutils'

class TestZillowData < Test::Unit::TestCase
  def test_open_rejects_missing_or_corrupt_geometry
    Dir.mktmpdir('shapelib-test-') do |dir|
      fixture = 'test/data/ZillowNeighborhoods-CA/ZillowNeighborhoods-CA'
      FileUtils.cp("#{fixture}.shp", File.join(dir, 'no_index.shp'))
      File.binwrite(File.join(dir, 'corrupt.shp'), 'not a shapefile')
      FileUtils.cp("#{fixture}.shx", File.join(dir, 'corrupt.shx'))
      %w[missing no_index corrupt].each do |name|
        filename = File.join(dir, name)
        assert_file_operation_failure('SHPOpen', filename) do |block|
          Shapelib::ShapeFile.open(filename, &block)
        end
      end
    end
  end

  def test_creation_rejects_nonexistent_parent
    Dir.mktmpdir('shapelib-test-') do |dir|
      filename = File.join(dir, 'absent', 'points')
      assert_file_operation_failure('SHPCreate', filename) do |block|
        Shapelib::ShapeFile.new(filename, Shapelib::Point, &block)
      end
      assert_empty Dir.children(dir)
    end
  end

  def test_creation_rejects_partial_failure_without_deleting_files
    Dir.mktmpdir('shapelib-test-') do |dir|
      filename = File.join(dir, 'points')
      Dir.mkdir("#{filename}.dbf")
      assert_file_operation_failure('DBFCreate', filename) do |block|
        Shapelib::ShapeFile.new(filename, Shapelib::Point, &block)
      end
      assert_path_exist "#{filename}.shp"
      assert_path_exist "#{filename}.shx"
      assert_true File.directory?("#{filename}.dbf")
    end
  end

  def test_file_creation_and_open_round_trip
    Dir.mktmpdir('shapelib-test-') do |dir|
      filename = File.join(dir, 'points')
      Shapelib::ShapeFile.new(filename, Shapelib::Point, [['name', Shapelib::String, 10]]) do |file|
        assert_equal 0, file.write(Shapelib::Point.new(1, 2, { 'name' => 'example' }))
      end
      Shapelib::ShapeFile.open(filename) do |file|
        assert_equal 1, file.size
        assert_equal 1, file.field_count
        shape = file.read(0)
        assert_equal [1.0], shape.xvals
        assert_equal [2.0], shape.yvals
        assert_equal 'example', shape['name']
      end
    end
  end

  def test_null_records_are_skipped_only_by_sequential_reads
    [[nil, 1], [1, nil, 2], [1, nil], [nil, nil, 1],
     [1, nil, nil, 2], [nil, nil]].each do |records|
      Dir.mktmpdir('shapelib-test-') do |dir|
        filename = File.join(dir, 'points')
        Shapelib::ShapeFile.new(filename, Shapelib::Point, [['id', Shapelib::Integer, 8]]) do |file|
          records.each_with_index do |value, index|
            shape = if value.nil?
                      Shapelib::Shape.new(empty_geometry(:Null).merge('id' => index))
                    else
                      Shapelib::Point.new(value, -value, { 'id' => index })
                    end
            file.write(shape)
          end
        end
        expected = records.each_index.reject { |index| records[index].nil? }
        Shapelib::ShapeFile.open(filename) do |file|
          assert_equal records.length, file.size
          records.each_with_index do |value, index|
            shape = file.read(index)
            if value.nil?
              assert_nil shape
              following = expected.find { |record| record > index }
              row = file.read
              following.nil? ? assert_nil(row) : assert_equal(following, row['id'])
            else
              assert_equal [value.to_f], shape.xvals
              assert_equal index, shape['id']
            end
          end
          file.rewind
          assert_equal expected, expected.map { file.read['id'] }
          assert_nil file.read
          assert_nil file.read
          2.times do
            ids = []
            file.each { |shape| ids << shape['id'] }
            assert_equal expected, ids
          end
          assert_equal records.length, file.size
        end
      end
    end
  end

  def test_geometry_only_reads_and_rejects_writes
    Dir.mktmpdir('shapelib-test-') do |dir|
      filename = File.join(dir, 'points')
      Shapelib::ShapeFile.new(filename, Shapelib::Point) do |file|
        file.write(Shapelib::Point.new(1, 2))
      end
      File.unlink("#{filename}.dbf")
      paths = %w[shp shx].map { |suffix| "#{filename}.#{suffix}" }
      contents = paths.map { |path| File.binread(path) }
      Shapelib::ShapeFile.open(filename, 'rb+') do |file|
        assert_equal 1, file.size
        assert_equal(-1, file.field_count)
        assert_nil file.fields
        assert_equal [1.0], file.read(0).xvals
        shapes = []
        file.each { |shape| shapes << shape }
        assert_equal 1, shapes.size
        assert_equal [2.0], shapes.first.yvals
        assert_raise(IOError) { file.write(Shapelib::Point.new(3, 4)) }
      end
      assert_equal contents, paths.map { |path| File.binread(path) }
    end
  end

  def test_hash_constructor_rejects_negative_counts
    [:n_vertices, :n_parts].each do |key|
      data = hash_geometry
      data[key] = -1
      assert_raise(ArgumentError) { Shapelib::Shape.new(data) }
    end
  end

  def test_hash_constructor_rejects_short_arrays
    [:part_type, :part_start, :xvals, :yvals, :zvals, :mvals].each do |key|
      data = hash_geometry
      count = data[[:part_type, :part_start].include?(key) ? :n_parts : :n_vertices]
      data[key] = data[key].take(count - 1)
      error = assert_raise(ArgumentError) { Shapelib::Shape.new(data) }
      assert_match(/#{key}.*#{count}/, error.message)
    end
  end

  def test_hash_constructor_rejects_out_of_bounds_part_starts
    [:ArcZ, :PolygonZ].each do |type|
      [-1, 5].each do |start|
        data = hash_geometry.merge(shape_type: type, part_start: [0, start])
        error = assert_raise(ArgumentError) { Shapelib::Shape.new(data) }
        assert_equal 'part_start[1] must be between 0 and 4', error.message
      end
    end
    GC.start
  end

  def test_hash_constructor_preserves_part_wkt
    { ArcZ: 'MULTILINESTRING((0 1, 4 5), (8 9, 12 13))',
      PolygonZ: 'POLYGON((0 1, 4 5), (8 9, 12 13))' }.each do |type, wkt|
      shape = Shapelib::Shape.new(hash_geometry.merge(shape_type: type))
      assert_equal [0, 2], shape.part_start
      assert_equal wkt, shape.wkt
    end
  end

  def test_hash_constructor_preserves_empty_parts
    { ArcZ: 'MULTILINESTRING', PolygonZ: 'POLYGON' }.each do |type, prefix|
      { [0, 0] => '((), (0 1, 4 5, 8 9, 12 13))',
        [0, 4] => '((0 1, 4 5, 8 9, 12 13), ())' }.each do |starts, body|
        shape = Shapelib::Shape.new(hash_geometry.merge(shape_type: type, part_start: starts))
        assert_equal starts, shape.part_start
        assert_equal prefix + body, shape.wkt
      end
    end
  end

  def test_hash_constructor_preserves_part_start_normalization_and_prefix_counts
    [:ArcZ, :PolygonZ].each do |type|
      expected = Shapelib::Shape.new(hash_geometry.merge(shape_type: type)).to_h
      [-1, 1, 5].each do |first|
        data = hash_geometry.merge(shape_type: type, part_start: [first, 2, -1, 5])
        assert_equal expected, Shapelib::Shape.new(data).to_h
      end
    end
  end

  def test_hash_constructor_preserves_matching_counts
    data = hash_geometry
    data['name'] = 'example'
    assert_equal data, Shapelib::Shape.new(data).to_h
  end

  def test_hash_constructor_preserves_explicit_prefix_counts
    data = hash_geometry
    data[:n_parts] = 1
    data[:n_vertices] = 2
    shape = Shapelib::Shape.new(data)
    assert_equal 1, shape.n_parts
    assert_equal 2, shape.n_vertices
    [:xvals, :yvals, :zvals, :mvals, :part_start, :part_type].each do |key|
      count = [:part_start, :part_type].include?(key) ? 1 : 2
      assert_equal data[key].take(count), shape.to_h[key]
    end
  end

  def test_hash_constructor_reads_each_field_once
    data = hash_geometry
    reads = Hash.new(0)
    input = Object.new
    input.define_singleton_method(:[]) do |key|
      reads[key] += 1
      raise 'field fetched twice' if reads[key] > 1
      data[key]
    end
    assert_equal data, Shapelib::Shape.new(input).to_h
    expected = [:shape_type, :shape_id, :n_parts, :n_vertices,
                :part_type, :part_start, :xvals, :yvals, :zvals, :mvals]
    assert_equal expected.sort, reads.keys.sort
    assert_equal [1], reads.values.uniq
  end

  def test_hash_constructor_snapshots_arrays_before_numeric_conversion
    [:part_type, :part_start, :xvals, :yvals, :zvals, :mvals].each do |key|
      [:grow, :clear].each do |mutation|
        data = hash_geometry
        expected = data.transform_values { |value| value.is_a?(Array) ? value.dup : value }
        array = data[key]
        original = array[0]
        number = key == :part_type ? 5 : original
        conversion = [:part_type, :part_start].include?(key) ? :to_int : :to_f
        value = Object.new
        value.define_singleton_method(conversion) do
          mutation == :grow ? array.concat([original] * 16) : array.clear
          number
        end
        array[0] = value
        assert_equal expected, Shapelib::Shape.new(data).to_h
        assert_equal mutation == :grow ? expected[key].length + 16 : 0, array.length
      end
    end
  end

  def test_hash_constructor_snapshots_later_arrays_before_numeric_conversion
    [:part_type, :part_start, :xvals, :yvals, :zvals, :mvals].each_cons(2) do |key, later_key|
      data = hash_geometry
      expected = data.transform_values { |value| value.is_a?(Array) ? value.dup : value }
      later = data[later_key]
      number = key == :part_type ? 5 : data[key][0]
      conversion = [:part_type, :part_start].include?(key) ? :to_int : :to_f
      value = Object.new
      value.define_singleton_method(conversion) do
        later.clear
        number
      end
      data[key][0] = value
      assert_equal expected, Shapelib::Shape.new(data).to_h
      assert_empty later
    end
  end

  def test_hash_constructor_preserves_optional_xy_arrays
    data = hash_geometry
    data[:xvals] = data[:yvals] = nil
    shape = Shapelib::Shape.new(data)
    assert_equal [0.0] * data[:n_vertices], shape.xvals
    assert_equal [0.0] * data[:n_vertices], shape.yvals
    assert_equal data[:zvals], shape.zvals
    assert_equal data[:mvals], shape.mvals
  end

  def test_hash_constructor_still_requires_counts_and_arrays
    [:n_vertices, :n_parts, :part_type, :part_start].each do |key|
      data = hash_geometry
      data[key] = nil
      assert_raise(TypeError) { Shapelib::Shape.new(data) }
    end
    [:zvals, :mvals].each do |key|
      data = hash_geometry
      data[key] = nil
      error = assert_raise(RuntimeError) { Shapelib::Shape.new(data) }
      assert_equal "missing #{key}", error.message
    end
  end

  def test_empty_points_reject_coordinate_reads_and_wkt
    { Point: [:m, :z], PointM: [:z], PointZ: [] }.each do |type, absent|
      shape = Shapelib::Shape.new(empty_geometry(type))
      assert_equal 0, shape.n_vertices
      assert_equal type, shape.to_h[:shape_type]
      ([:x, :y, :m, :z, :wkt, :to_s] - absent).each do |method|
        error = assert_raise(ArgumentError) { shape.public_send(method) }
        assert_equal 'point has no vertices', error.message
      end
      absent.each { |method| assert_nil shape.public_send(method) }
    end
  end

  def test_empty_lines_reject_wkt
    [Shapelib::Arc, Shapelib::ArcM, Shapelib::ArcZ].each do |klass|
      [klass.new(:Ring), Shapelib::Shape.new(empty_geometry(klass))].each do |shape|
        assert_equal 0, shape.n_vertices
        [:wkt, :to_s].each do |method|
          error = assert_raise(ArgumentError) { shape.public_send(method) }
          assert_equal 'cannot format an empty line', error.message
        end
      end
    end
  end

  def test_unsupported_shape_types_reject_wkt
    { Null: 0, 0 => 0, 99 => 99 }.each do |type, number|
      shape = Shapelib::Shape.new(empty_geometry(type))
      assert_equal number == 0 ? :Null : number, shape.shape_type
      assert_equal shape.shape_type, shape.to_h[:shape_type]
      [:wkt, :to_s].each do |method|
        error = assert_raise(ArgumentError) { shape.public_send(method) }
        assert_equal "unsupported WKT shape type #{number}", error.message
      end
    end
  end

  def test_nonempty_point_coordinates_and_wkt
    [Shapelib::Point.new(1, 2), Shapelib::PointM.new(1, 2, 3),
     Shapelib::PointZ.new(1, 2, 3, 4)].each_with_index do |shape, index|
      assert_equal 1.0, shape.x
      assert_equal 2.0, shape.y
      index == 0 ? assert_nil(shape.m) : assert_equal(3.0, shape.m)
      index == 2 ? assert_equal(4.0, shape.z) : assert_nil(shape.z)
      assert_equal 'POINT(1 2)', shape.wkt
      assert_equal shape.wkt, shape.to_s
    end
  end

  def test_nonempty_single_line_wkt
    [Shapelib::Arc, Shapelib::ArcM, Shapelib::ArcZ].each do |klass|
      shape = klass.new([1, 2], [3, 4])
      assert_equal 'LINESTRING(1 2, 3 4)', shape.wkt
      assert_equal shape.wkt, shape.to_s
    end
  end

  def test_geometry_constructors_reject_empty_inputs
    part = [[0, 0], [1, 1]]
    classes = [Shapelib::Arc, Shapelib::ArcM, Shapelib::ArcZ,
               Shapelib::Polygon, Shapelib::PolygonM, Shapelib::PolygonZ, Shapelib::MultiPatch]
    classes.each do |klass|
      [[], [[]], [[], part], [part, []]].each do |args|
        assert_raise(ArgumentError) { klass.new(*args) }
      end
    end
  end

  def test_multipart_constructor_rejects_non_array_part
    error = assert_raise(ArgumentError) { Shapelib::Arc.new([[0, 0], [1, 1]], nil) }
    assert_equal 'arg 1 must be Array', error.message
  end

  def test_geometry_constructors_accept_single_and_multiple_parts
    part = [[0, 0], [1, 0], [1, 1], [0, 0]]
    [Shapelib::Arc, Shapelib::Polygon].each do |klass|
      single = klass.new(*part)
      assert_equal 1, single.n_parts
      assert_equal 4, single.n_vertices
      assert_equal [0.0, 1.0, 1.0, 0.0], single.xvals
      multiple = klass.new(part, part)
      assert_equal 2, multiple.n_parts
      assert_equal 8, multiple.n_vertices
      assert_equal single.xvals * 2, multiple.xvals
    end
  end

  def test_multipart_constructor_accepts_explicit_part_type
    shape = Shapelib::MultiPatch.new([:TriangleStrip, [0, 0], [1, 0], [0, 1]])
    assert_equal 1, shape.n_parts
    assert_equal 3, shape.n_vertices
    assert_equal [:TriangleStrip], shape.part_type
    assert_equal [0.0, 1.0, 0.0], shape.xvals
  end

  def test_geometry_coordinate_defaults_are_preserved
    shape = Shapelib::Arc.new([1, 2], [])
    assert_equal [1.0, 0.0], shape.xvals
    assert_equal [2.0, 0.0], shape.yvals
  end

  def test_open_filename_rejects_nul
    filename = "test/data/ZillowNeighborhoods-CA/ZillowNeighborhoods-CA\0ignored"
    assert_raise(ArgumentError) { Shapelib::ShapeFile.open(filename) {} }
  end

  def test_new_filename_rejects_nul
    Dir.mktmpdir('shapelib-test-') do |dir|
      filename = "#{File.join(dir, 'points')}\0ignored"
      assert_raise(ArgumentError) { Shapelib::ShapeFile.new(filename, Shapelib::Point) {} }
      assert_empty Dir.children(dir)
    end
  end

  def test_open_mode_rejects_nul
    filename = 'test/data/ZillowNeighborhoods-CA/ZillowNeighborhoods-CA'
    assert_raise(ArgumentError) { Shapelib::ShapeFile.open(filename, "rb\0ignored") {} }
  end

  def test_field_creation_rejects_nul
    Dir.mktmpdir('shapelib-test-') do |dir|
      Shapelib::ShapeFile.new(File.join(dir, 'points'), Shapelib::Point) do |file|
        assert_raise(ArgumentError) { file.add_field("name\0ignored", Shapelib::String, 10) }
        assert_equal 0, file.field_count
      end
    end
  end

  def test_field_lookup_rejects_nul
    Dir.mktmpdir('shapelib-test-') do |dir|
      Shapelib::ShapeFile.new(File.join(dir, 'points'), Shapelib::Point) do |file|
        file.add_field('name', Shapelib::String, 10)
        assert_equal 0, file.field_index('name')
        assert_raise(ArgumentError) { file.field_index("name\0ignored") }
      end
    end
  end

  def test_attribute_lookup_rejects_nul
    point = Shapelib::Point.new(1, 2)
    point['name'] = 42
    assert_raise(ArgumentError) { point["name\0ignored"] }
  end

  def test_attribute_assignment_rejects_nul
    point = Shapelib::Point.new(1, 2)
    point['name'] = 42
    assert_raise(ArgumentError) { point["name\0ignored"] = 43 }
    assert_equal 42, point['name']
  end

  def test_attribute_value_rejects_nul_without_changing_previous_value
    [42, 'before'].each do |value|
      point = Shapelib::Point.new(1, 2)
      point['name'] = value
      assert_raise(ArgumentError) { point['name'] = "after\0ignored" }
      assert_equal value, point['name']
    end
  end

  def test_attribute_replacement_between_supported_types
    values = [42, 1.5, 'before', nil]
    values.product(values).each do |before, after|
      point = Shapelib::Point.new(1, 2)
      point['name'] = before
      assert_same point, point.send(:[]=, 'name', after)
      assert_equal after, point['name']
      assert_equal !after.nil?, point.to_h.key?('name')
    end
    point = nil
    GC.start
  end

  def test_cleared_attribute_slot_can_be_reused
    [42, 1.5, 'before', nil].each do |value|
      point = Shapelib::Point.new(1, 2)
      point['old'] = value
      point['old'] = nil
      point['new'] = 'after'
      assert_nil point['old']
      assert_equal 'after', point['new']
      assert_equal ['new'], point.to_h.keys.grep(String)
    end
    point = nil
    GC.start
  end

  def test_invalid_attribute_replacement_preserves_previous_value
    [42, 1.5, 'before', nil].each do |value|
      point = Shapelib::Point.new(1, 2)
      point['name'] = value
      assert_raise(TypeError) { point['name'] = Object.new }
      assert_equal value, point['name']
      assert_raise(ArgumentError) { point['name'] = "after\0ignored" }
      assert_equal value, point['name']
      if 0.size > 4
        assert_raise(RangeError) { point['name'] = 2**31 }
        assert_equal value, point['name']
      end
    end
    point = nil
    GC.start
  end

  def test_replacing_attributes_read_from_file
    fixture = 'test/data/ZillowNeighborhoods-CA/ZillowNeighborhoods-CA'
    Shapelib::ShapeFile.open(fixture) do |file|
      shape = file.read(0)
      names = shape.to_h.select { |key, value| key.is_a?(String) && value.is_a?(String) }.keys
      assert_not_empty names
      names.each do |name|
        shape[name] = 'replacement'
        assert_equal 'replacement', shape[name]
        shape[name] = nil
        assert_nil shape[name]
        assert_false shape.to_h.key?(name)
      end
      shape = nil
      GC.start
    end
  end

  def test_attribute_name_boundaries
    point = Shapelib::Point.new(1, 2)
    ['a' * 10, 'b' * 11].each do |name|
      point[name] = 42
      assert_equal 42, point[name]
      assert_equal 42, point.to_h[name]
    end
  end

  def test_long_attribute_names_are_truncated
    name = 'long_attribute_name' * 8
    prefix = name[0, 11]
    [0, 16].each do |count|
      point = Shapelib::Point.new(1, 2)
      count.times { |i| point["field#{i}"] = i + 1 }
      point[name] = 42
      assert_equal 42, point[name]
      assert_equal 42, point[prefix]
      assert_equal 42, point[prefix.upcase]
      assert_equal 42, point.to_h[prefix]
      assert_equal count + 1, point.to_h.keys.grep(String).size
      point["#{prefix}_other"] = 43
      assert_equal 43, point[name]
      assert_equal count + 1, point.to_h.keys.grep(String).size
      count.times { |i| assert_equal i + 1, point["field#{i}"] }
    end
  end

  def test_point_z_coordinate
    point = Shapelib::PointZ.new(1, 2, 3, 4)
    assert_equal 3.0, point.m
    assert_equal 4.0, point.z
  end

  def test_open_block_closes_file
    assert_block_closes_file do |block|
      Shapelib::ShapeFile.open('test/data/ZillowNeighborhoods-CA/ZillowNeighborhoods-CA', &block)
    end
  end

  def test_new_block_closes_file
    Dir.mktmpdir('shapelib-test-') do |dir|
      assert_block_closes_file do |block|
        Shapelib::ShapeFile.new(File.join(dir, 'points'), Shapelib::Point, &block)
      end
    end
  end
  
  def test_file_loading
    filename = "test/data/ZillowNeighborhoods-CA/ZillowNeighborhoods-CA"
    file = Shapelib::ShapeFile.open(filename)
    
    assert_equal 948, file.size
    file.each do |shape|
      p shape
    end
  ensure
    file.close if file
  end

  private

  def assert_file_operation_failure(operation, filename)
    yielded = false
    error = assert_raise(IOError) { yield proc { yielded = true } }
    assert_false yielded
    assert_match(/#{Regexp.escape(operation)}/, error.message)
    assert_match(/#{Regexp.escape(filename)}/, error.message)
  end

  def empty_geometry(type)
    { shape_type: type, n_vertices: 0, n_parts: 0, part_type: [], part_start: [],
      xvals: [], yvals: [], zvals: [], mvals: [] }
  end

  def hash_geometry
    Shapelib::ArcZ.new([[0, 1, 2, 3], [4, 5, 6, 7]],
                      [[8, 9, 10, 11], [12, 13, 14, 15]]).to_h
  end

  def assert_block_closes_file
    [nil, RuntimeError.new('block failure')].each do |error|
      file = nil
      block = proc do |opened|
        file = opened
        assert_operator file.field_count, :>=, 0
        raise error if error
        :ignored
      end
      if error
        assert_same error, assert_raise(RuntimeError) { yield block }
      else
        assert_nil yield(block)
      end
      assert_equal(-1, file.field_count)
    ensure
      file.close if file
    end
  end
end
