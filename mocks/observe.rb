
class Observe
  def initialize
    @observers = []
  end
  def register &block
    @observers << block
  end
  def notify *args
    @observers.each{|o|o.call(*args)}
  rescue Exception
    puts "Observe: Untammed code detected"
  end
end

