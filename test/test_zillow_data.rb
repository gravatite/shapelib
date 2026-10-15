require 'shapelib'
require 'test/unit'
require 'tmpdir'

class TestZillowData < Test::Unit::TestCase
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
