require 'shapelib'
require 'test/unit'
require 'tmpdir'

class TestZillowData < Test::Unit::TestCase
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
