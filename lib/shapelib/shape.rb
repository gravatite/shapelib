module Shapelib
  class Shape
    def each
      latlngs.each do |l|
        yield l
      end
    end
    
    def latlngs
      @latlngs ||= yvals.zip(xvals)
    end
    
    def inspect
      self.class.to_s + self.to_h.inspect
    end
  end
end
      