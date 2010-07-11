require 'shapelib'
require 'test/unit'

class TestZillowData < Test::Unit::TestCase
  
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
end